// Infinite scroll.

function ep_initialiseInfiniteScroll(containerElement) {

    // The number of result rows to show.
    const numberOfResults = 8;

    // For the pulse animation.
    const heightPerSecond = 500;

    // Extra margin for preview items, if needed.
    const previewItemMargin = 10;

    const controlsBottomElement = containerElement.querySelector("div.ep_search_controls_bottom");

    let shuffledResults;
    let shuffledParts;

    const ep_loader_template = `
        <style>
            rect { fill: #ddd; stroke: none; }
            .all { fill: url(#loadingGradient); }
        </style>
        <defs>
            <linearGradient id="loadingGradient" fy="0" x1="0" y1="0" x2="0" y2="0" gradientUnits="userSpaceOnUse">
                <stop offset="0" stop-color="#eee"/>
                <stop offset=".25" stop-color="#eee"><animate attributeName="offset" values="-0.5;1.5" repeatCount="indefinite"/></stop>
                <stop offset=".35" stop-color="#eee"><animate attributeName="offset" values="-0.4;1.6" repeatCount="indefinite"/></stop>
                <stop offset=".36" stop-color="#ddd"><animate attributeName="offset" values="-0.39;1.61" repeatCount="indefinite"/></stop>
                <stop offset=".44" stop-color="#ddd"><animate attributeName="offset" values="-0.31;1.69" repeatCount="indefinite"/></stop>
                <stop offset=".45" stop-color="#eee"><animate attributeName="offset" values="-0.3;1.7" repeatCount="indefinite"/></stop>
                <stop offset="1" stop-color="#eee"/>
            </linearGradient>
            <mask maskUnits="userSpaceOnUse" id="mask"/>
        </defs>
        <rect class="all" x="0" y="0" fill="url(#loadingGradient)" mask="url(#mask)""/>
    `;

    const svgNS = "http://www.w3.org/2000/svg";

    function updateScrollPreview(svg) {

        const rowExtents = shuffledParts.map(function (item) {
            return {
                rect: item.item.getBoundingClientRect(),
                parts: item.parts.map(part => part.getBoundingClientRect())
            };
        });

        // Get squares.

        let top = 0;
        let squares = [];
        let maxRight = 0;
        let maxBottom = 0;

        for (const extent of rowExtents) {

            for (const part of extent.parts) {

                const square = {
                    left: part.left - extent.rect.left,
                    top: top + part.top - extent.rect.top,
                    width: part.width,
                    height: part.height,
                };

                squares.push(square);

                maxRight = Math.max(maxRight, square.left + square.width);
                maxBottom = Math.max(maxBottom, square.top + square.height);
            }

            top += extent.rect.height + previewItemMargin;
        }

        // Generate SVG.

        const mainRect = svg.querySelector("rect.all");
        const mask = svg.querySelector("mask");
        const loadingGradient = svg.querySelector("#loadingGradient");

        svg.setAttribute("width", maxRight);
        svg.setAttribute("height", maxBottom);

        mainRect.setAttribute("width", maxRight);
        mainRect.setAttribute("height", maxBottom);

        loadingGradient.setAttribute("y2", maxBottom);

        const rects = squares.map(function (square) {

            const rect = document.createElementNS(svgNS, "rect");

            rect.setAttribute("x", square.left);
            rect.setAttribute("y", square.top);
            rect.setAttribute("width", square.width);
            rect.setAttribute("height", square.height);

            return rect;
        });

        mask.replaceChildren(...rects);

        const duration = maxBottom / heightPerSecond;

        for (const animation of svg.querySelectorAll("animate")) {
            animation.setAttribute("dur", `${duration}s`);
        }
    }

    function generateDocumentCitationScrollPreview() {

        const allResults = Array.from(containerElement.querySelector(".ep_search_results .ep_paginate_list").querySelectorAll("div.ep_search_result"));

        // Shuffle items.

        shuffledResults = allResults
            .slice(-numberOfResults)
            .map(value => ({ value, sort: Math.random() }))
            .sort((a, b) => a.sort - b.sort)
            .map(({ value }) => value);

        shuffledParts = shuffledResults.map(function (result) {

            const divs = result.querySelectorAll(":scope > div");

            const number = divs.item(0);
            const citation = divs.item(1);
            const images = Array.from(divs.item(2).querySelectorAll(".ep_preview_container img.ep_doc_icon"));

            return {
                item: result,
                parts: [number, citation, ...images]
            };
        });

        const svg = document.createElementNS(svgNS, "svg");

        svg.innerHTML = ep_loader_template;
        svg.setAttribute("class", "ep_infiniteScrollElement");

        updateScrollPreview(svg);

        const resizeObserver = new ResizeObserver(function () {
            updateScrollPreview(svg);
        });

        for (const item of shuffledParts) {

            resizeObserver.observe(item.item);

            for (const part of item.parts) {
                resizeObserver.observe(part);
            }
        }

        containerElement.querySelector(".ep_search_results .ep_paginate_list").insertAdjacentElement("afterend", svg);
    }

    function initialiseSearchInfiniteScroll() {

        let nextPageUrl = containerElement.querySelector(".ep_search_control a.ep_next").href;
        let processing = false;

        async function getNextPage() {

            if (processing) {
                return;
            }

            processing = true;

            const response = await fetch(nextPageUrl);
            const bodyText = await response.text();

            const doc = document.createRange().createContextualFragment(bodyText);

            const newResults = doc.querySelectorAll(".ep_search_result_list .ep_search_results .ep_search_result");

            for (const newResult of newResults) {
                containerElement.querySelector(".ep_search_results .ep_paginate_list").appendChild(newResult);
            }

            const nextLink = doc.querySelector(".ep_search_control a.ep_next");

            removeScrollElement();

            if (nextLink) {
                nextPageUrl = nextLink.href;
                addScrollElement();
            }

            // Dispatch an event when we finish loading the next search elements so they can be highlighted
            document.dispatchEvent(new Event("ep_infiniteScrollEvent"));

            processing = false;
        }

        // window.getNextPage = getNextPage;

        function addScrollElement() {

            if (!containerElement.querySelector(".ep_infiniteScrollElement")) {
                generateDocumentCitationScrollPreview();
            }

            if (controlsBottomElement) {
                controlsBottomElement.style.display = 'none';
            }

            let options = {
                root: null,
                rootMargin: "0px",
                threshold: 0.1,
            };

            function moreItemsObserverFunction(entries) {

                if (entries[0].intersectionRatio <= 0)
                    return;

                getNextPage();
            }

            let observer = new IntersectionObserver(moreItemsObserverFunction, options);

            observer.observe(containerElement.querySelector(".ep_infiniteScrollElement"));
        }

        function removeScrollElement() {

            const scrollElement = containerElement.querySelector(".ep_infiniteScrollElement");

            if (scrollElement) {
                scrollElement.remove();
            }

            if (controlsBottomElement) {
                controlsBottomElement.style.display = '';
            }
        }

        addScrollElement();
    }

    if (containerElement.querySelector(".ep_search_control a.ep_next")) {
        initialiseSearchInfiniteScroll();
    }
}

document.addEventListener("DOMContentLoaded", function () {

    const searchResultList = document.querySelector(".ep_search_result_list");

    if (searchResultList) {
        ep_initialiseInfiniteScroll(searchResultList);
    }
});
