//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "base64-sol/base64.sol";
import "./Problems.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StringsExtended.sol";
import "hardhat/console.sol";

/// @title Metadata
/// @notice
/// @author @okwme
/// @dev The updateable and replaceable metadata contract

contract Metadata is Ownable {
    address payable public problems;
    uint256 constant radiusMultiplyer = 100;

    constructor() {}

    // string public baseURI = "https://";

    // /// @dev sets the baseURI can only be called by the owner
    // /// @param baseURI_ the new baseURI
    // function setbaseURI(string memory baseURI_) public onlyOwner {
    //     baseURI = baseURI_;
    // }

    // /// @dev generates the metadata
    // /// @param tokenId the tokenId
    // /// @return _ the metadata
    // function getMetadata(uint256 tokenId) public view returns (string memory) {
    //     return
    //         string(
    //             abi.encodePacked(baseURI, StringsExtended.toString(tokenId), ".json")
    //         );
    // }

    /**
     * @dev Throws if id doesn't exist
     */
    modifier existsModifier(uint256 id) {
        require(exists(id), "DOES NOT EXIST");
        _;
    }

    function exists(uint256 id) public view returns (bool) {
        return Problems(problems).ownerOf(id) != address(0);
    }

    /// @dev generates the metadata
    /// @param tokenId the tokenId
    function getMetadata(
        uint256 tokenId
    ) public view existsModifier(tokenId) returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            getName(tokenId),
                            '", "description": "asdf", "image": "',
                            getSVG(tokenId),
                            '",',
                            '"animation_url": "',
                            getHTML(tokenId),
                            '",',
                            '"attributes": ',
                            getAttributes(tokenId),
                            "}"
                        )
                    )
                )
            );
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked("Problem #", StringsExtended.toString(tokenId))
            );
    }

    function getHTML(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "<html><body><img src='",
                            getSVG(tokenId),
                            "'></body></html>"
                        )
                    )
                )
            );
    }

    /// @dev function to generate a SVG String
    function getSVG(
        uint256 tokenId
    ) public view existsModifier(tokenId) returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '<?xml version="1.0" encoding="utf-8"?><svg xmlns="http://www.w3.org/2000/svg"  height="100%" width="100%" viewBox="0 0 1000 1000" style="background-color:grey;"><style></style>',
                            getPath(tokenId),
                            '<text x="50" y="550" class="name">',
                            getName(tokenId),
                            "</text></svg>"
                        )
                    )
                )
            );
    }

    function getPath(uint256 tokenId) public view returns (string memory) {
        // const { seed, bodyCount, tickCount, bodiesProduced } = problem
        string memory path = "";
        (
            bytes32 seed,
            uint256 bodyCount,
            uint256 tickCount,
            uint256 bodiesProduced
        ) = Problems(problems).problems(tokenId);

        uint256[10] memory bodyIds = Problems(problems).getProblemBodyIds(
            tokenId
        );
        uint256 scalingFactor = Problems(problems).scalingFactor();
        for (uint256 i = 0; i < bodyCount; i++) {
            Problems.Body memory body = Problems(problems).getProblemBodyData(
                tokenId,
                bodyIds[i]
            );

            uint256 scaledRadius = body.radius *
                4 +
                radiusMultiplyer *
                scalingFactor;
            uint256 radiusRounded = (scaledRadius / scalingFactor);
            string memory radius = StringsExtended.toString(radiusRounded);
            string memory radiusDecimalsString = StringsExtended.toString(
                scaledRadius - (radiusRounded * scalingFactor)
            );

            uint256 pxScaled = body.px / scalingFactor;
            uint256 pxDecimals = body.px - (pxScaled * scalingFactor);
            string memory pxString = string(
                abi.encodePacked(
                    StringsExtended.toString(pxScaled),
                    ".",
                    StringsExtended.toString(pxDecimals)
                )
            );
            uint256 pyScaled = body.py / scalingFactor;
            uint256 pyDecimals = body.py - (pyScaled * scalingFactor);
            string memory pyString = string(
                abi.encodePacked(
                    StringsExtended.toString(pyScaled),
                    ".",
                    StringsExtended.toString(pyDecimals)
                )
            );
            string memory bodyIDString = StringsExtended.toString(body.bodyId);
            string memory transformOrigin = string(
                abi.encodePacked(
                    "transform-origin: ",
                    pxString,
                    "px ",
                    pyString,
                    "px; "
                )
            );
            path = string(
                abi.encodePacked(
                    path,
                    "<style> @keyframes moveEllipse",
                    bodyIDString,
                    " { 0% { ",
                    transformOrigin,
                    " transform: rotate(0deg) translate(0px, 10px); } 100% { ",
                    transformOrigin,
                    " transform: rotate(360deg) translate(0px, 10px); } }",
                    "ellipse#id-",
                    bodyIDString,
                    " { animation: moveEllipse",
                    bodyIDString,
                    " 4s infinite linear; animation-delay: -",
                    StringsExtended.toString(i),
                    "s; }</style>",
                    '<ellipse id="id-',
                    bodyIDString,
                    '" ry="',
                    radius,
                    ".",
                    radiusDecimalsString,
                    '" rx="',
                    radius,
                    ".",
                    radiusDecimalsString,
                    '" cy="',
                    pyString,
                    '" cx="',
                    pxString,
                    '" fill="#',
                    seedToColor(body.seed),
                    '" />'
                )
            );
        }

        return path;
    }

    function seedToColor(bytes32 seed) public view returns (string memory) {
        string memory result = StringsExtended.toHexString(
            uint256(seed) & 0xffffff,
            3
        );
        return result;
    }

    /// @dev generates the attributes as JSON String
    function getAttributes(
        uint256 tokenId
    ) internal view returns (string memory) {
        uint256 value = 0;
        uint256 value2 = 1;
        return
            string(
                abi.encodePacked(
                    "[",
                    '{"trait_type":"ASDF","value":"',
                    value,
                    '"}, {"trait_type":"ASDF2","value":"',
                    value2,
                    '"}]'
                )
            );
    }

    function updateProblemsAddress(address payable problems_) public onlyOwner {
        problems = problems_;
    }
}
