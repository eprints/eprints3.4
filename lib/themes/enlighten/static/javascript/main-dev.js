function Social(e) {
    jQuery.ajaxSetup({
        async: "false"
    }), social = this, social.accounts = e, social.feedurl = "//" + window.location.host + "/feeds/social/index.html?", social.tilestart = '<div style="display:none;" class="contentPanel socialTile promo singleContentElement TileBackgroundAlt2">', social.tilecontent = "", social.tileend = "</div>", social.tilearray = [], social.modalarray = [], social.slideno, social.writetiles = function() {
        jQuery.each(social.accounts, function(e) {
            social.accounts[e] || delete social.accounts[e]
        }), jQuery.ajax({
            dataType: "json",
            url: social.feedurl,
            data: social.accounts,
            success: function(e) {
                e.sort(function() {
                    return Math.random() - .5
                });
                var t = 0;
                jQuery.each(e, function(i) {
                    if (social.networkimage = '<div class="tile_social_icon">', null != e[i].link && (social.networkimage += '<a target="blank" href="' + e[i].link + '">'), social.networkimage += '<img alt="' + e[i].source + ' icon" width="25px" height="25px" src="http://www.gla.ac.uk/1t4/generic/images/social/' + e[i].source + '.png" />', null != e[i].link && (social.networkimage += "</a>"), social.networkimage += "</div>", null != e[i].image && social.modalarray.push('<li style="display:none"><div class="socialmodalimage"><img alt="' + e[i].image + '" src="' + e[i].image + '" /></div>' + social.networkimage + '<div class="socialtext"><p>' + e[i].text + "</p></div></li>"), social.tilecontent = "", social.tilecontent += social.tilestart, null != e[i].image ? (social.tilecontent += '<div class="image socialimage" data-slideno="' + i + '"><a class="open-popup" href="" data-slideno="' + t + '"><img class="socialimagesrc" alt="' + e[i].image + '" src="' + e[i].image + '" /></a></div>', t++) : social.tilecontent += '<div style="height:30px; width:100%"></div>', null != e[i].text) {
                        var n = e[i].text.split(" ");
                        n.length > 40 ? (jQuery.each(n, function(e) {
                            e > 40 && delete n[e]
                        }), n.push("...read more"), text = n.join(" ")) : text = e[i].text
                    }
                    social.tilecontent += '<div class="text"><p>' + text + "</p>", social.tilecontent += "</div>", social.tilecontent += social.networkimage, social.tilecontent += social.tileend, jQuery("#socialloader").after(social.tilecontent), social.tilearray.push(social.tilecontent)
                }), jQuery("#socialloader").hide(), jQuery(".socialTile").fadeIn("fast"), initPromoGrid(), forceResize(), social.carousel = '<div class="responsiveContent xtensibleCarousel contentPanel clear " style="position: relative; width:100%"><div class="blockTextAndImage generic flexContainer"><div class="socialslider"><ul class="rotatingPanel slides">' + social.modalarray.join("") + "</ul></div></div></div>", jQuery(".open-popup").click(function() {
                    return social.slideno = jQuery(this).data("slideno"), jQuery.magnificPopup.open({
                        items: {
                            src: social.carousel
                        },
                        gallery: {
                            enabled: !0
                        },
                        type: "inline",
                        mainClass: "mfp-with-zoom",
                        callbacks: {
                            open: function() {
                                jQuery(".socialslider").flexslider({
                                    controlNav: !0,
                                    slideshow: !1,
                                    slideshowSpeed: 6e3,
                                    animationSpeed: 300,
                                    startAt: social.slideno,
                                    animation: "slide",
                                    smoothHeight: !0,
                                    touch: !0,
                                    easing: "swing",
                                    pauseOnAction: !0,
                                    pauseOnHover: !0,
                                    controlsContainer: ".pageCarouselBlock .controls",
                                    useCSS: !1
                                })
                            }
                        }
                    }), !1
                })
            }
        })
    }
}

function alternateRows() {
    jQuery("#pageContent #mainpage .maincontent table.StripedTable tr:even, #pageContent #mainpage .maincontent table.stripedtable tr:even, #pageContent #mainpage .maincontent .newsstory:even").addClass("alt")
}

function isdefined(e) {
    return "undefined" == typeof window[e] ? !1 : !0
}

function IsResponsivePage() {
    return !jQuery.browser.msie || jQuery.browser.msie && parseFloat(jQuery.browser.version) >= 9 ? !0 : !1
}

function clearOnEnter() {
    jQuery.browser.msie && parseFloat(jQuery.browser.version) <= 9 && jQuery(".clearOnEnter, #siteSearch form #ssKeywords, #individualSearch form #isKeywords").each(function() {
        jQuery(this).data("swap", jQuery(this).attr("placeholder")), jQuery(this).val(jQuery(this).data("swap"))
    }).bind("focus", function() {
        jQuery(this).val() == jQuery(this).data("swap") && jQuery(this).val("")
    }).bind("blur", function() {
        "" == jQuery(this).val() && jQuery(this).val(jQuery(this).data("swap"))
    })
}

function StringIsNullOrEmpty(e) {
    return null == e || "undefined" == e || "" == e ? !0 : !1
}

function setPageHeight() {
    var e = jQuery("#mainpage").outerHeight(),
        t = 0;
    "none" == jQuery(".dropdownNav").css("display") ? (jQuery(".aside").children().each(function() {
        t += jQuery(this).outerHeight(!0)
    }), t + _contingency > e ? jQuery("#pageContent").css("min-height", t + _contingency) : jQuery("#pageContent").css("min-height", e)) : jQuery("#pageContent").removeAttr("style")
}

function positionBackgroundImage(e) {
    var t = isFinite(e) ? e : 0,
        i = jQuery("#pageContent").width(),
        n = jQuery("#pageContainer").width(),
        a = 0;
    a = i + ((n - i) / 2 + t), jQuery("#pageBackgroundImage").css({
        left: a + "px",
        right: "initial"
    })
}

function getDropDownListPageContentHeight() {
    var e = jQuery("#pageContent");
    e.attr("style", "");
    var t = e.height(),
        i = jQuery("ul.menu").outerHeight(!0) + jQuery(".dropdownNav").height() + _contingency;
    return jQuery("#pageContent").hasClass("alteredHeight") && i > t ? t + (i - t) : t
}

function setViewStateForContentTab() {
    jQuery("#tabs").length > 0 && jQuery("#tabs").children("div").each(jQuery(window).width() >= _maxNarrowWidth ? function() {
        jQuery(this).addClass(_uiTabPanelPlugInRemoveClass), jQuery(jQuery(".ui-tabs-selected a").attr("href")).removeClass(_uiTabPanelPlugInRemoveClass)
    } : function() {
        jQuery(this).removeClass(_uiTabPanelPlugInRemoveClass)
    })
}

function postitionDropDownMenu() {
    var e = jQuery(".dropdownNav .textBox");
    if (e.length > 0) {
        var t = e[0].offsetTop + e.outerHeight() - 1;
        jQuery("ul.menu").css("top", t)
    }
}

function RetractOpenDropDownListNav() {
    "block" == jQuery("ul.menu").css("display") && jQuery(".dropdownNav .textBox").trigger("mouseup")
}

function HideOpenNavigation() {
    jQuery(".dropdownButton").each(function() {
        var e = jQuery(this);
        e.hasClass("open") && e.trigger("mouseup")
    })
}

function generateDropDownListNav() {
    if (jQuery("#sNav ul").html()) {
        var e = jQuery(".dropdownNav .textBox");
        jQuery("ul.menu ").hide(), jQuery("ul.menu").append(jQuery("#sNav ul").html()), e.find("p").text("In this section")
    } else jQuery(".dropdownNav").remove(), jQuery(".aside").css({
        "background-image": "none"
    });
    0 != jQuery(".dropdownNav").length && e.mouseup(function() {
        if (HideOpenNavigation(), "block" == jQuery("ul.menu").css("display")) {
            if (jQuery("#pageContent").hasClass("alteredHeight")) {
                var e = jQuery("#pageContent");
                e.attr("style", ""), jQuery("#pageContent").removeClass("alteredHeight"), jQuery("#pageContent").animate({
                    height: e.height(),
                    duration: 2e3
                }), jQuery("#pageContent").removeAttr("style")
            }
            jQuery("ul.menu").slideUp("fast")
        } else jQuery("#pageContent").addClass("alteredHeight"), jQuery("#pageContent").height(getDropDownListPageContentHeight()), jQuery("ul.menu").slideDown()
    }), jQuery(".dropdownButton").mouseup(function() {
        RetractOpenDropDownListNav();
        var e = jQuery(this);
        return jQuery(".dropdownButton").each(function() {
            jQuery(this).parent().attr("id") != e.parent().attr("id") && (jQuery(this).removeClass("open"), jQuery(this).parent("div").first().find("ul").hide())
        }), e.toggleClass("open"), e.parent("div").first().find("ul").toggle(), !1
    })
}

function setTextPanelHeight(e) {
    e.children("li").each(function() {
        0 == jQuery(this).find(".text").children().length ? (jQuery(this).find(".text").hide(), jQuery(this).find(".image").css("width", "100%")) : jQuery(this).find(".text").css("height", jQuery(this).height())
    })
}

function pgtDrop() {
    jQuery(".dropdown").hide(), jQuery(".otherprogs").click(function() {
        jQuery(this).hasClass("otherprogsopen") ? (jQuery(".dropdown").slideUp("fast"), jQuery(".otherprogsopen").removeClass("otherprogsopen")) : (jQuery(".dropdown").slideUp("fast"), jQuery(this).addClass("otherprogsopen").find(".dropdown").slideToggle("fast"), e.preventDefault())
    }), jQuery(".otherprogs").length > 0 && jQuery(document).click(function(e) {
        jQuery(e.target).is(".otherprogs p") || jQuery(e.target).is(".otherprogs") || jQuery(e.target).is(".dropdown") || (jQuery(".dropdown").slideUp("fast"), jQuery(".otherprogsopen").removeClass("otherprogsopen"))
    })
}

function pgtDropAdj() {
    jQuery(".dropdown").each(function() {
        if (jQuery(window).width() < _maxNarrowWidth) {
            var e = jQuery(this).parent().innerWidth();
            jQuery(this).css({
                width: e + "px"
            })
        }
        var t = jQuery(this).parent().outerHeight();
        jQuery(this).css({
            top: t + "px"
        })
    })
}

function drawNewsAndEventNav() {
    jQuery(".newsAndEventsNav").height(jQuery(".newsAndEventsNav li").first().outerHeight())
}

function forceResize() {
    jQuery(window).resize()
}

function DeviceOrientationChangeEvent() {
    setTimeout(forceResize, 250)
}

function initPromoGrid() {
    var e = jQuery("div.contentPanel.singleContentElement"),
        t = 2,
        i = [],
        n = 0;
    i.push([]), e.each(function() {
        i[n].push(jQuery(this)), jQuery(this).next().hasClass("contentPanel") && jQuery(this).next().hasClass("singleContentElement") || (i.push([]), n++)
    }), jQuery(i).each(function(e) {
        var i = [],
            n = null,
            a = 0,
            s = 0,
            o = 0;
        o = Math.ceil(this.length / t), jQuery(this[0]).after("<div class='contentPanelContainer" + e + "'></div>"), n = jQuery("div.contentPanelContainer" + e);
        for (var r = 0; o > r; r++) n.append("<div class='row'></div>");
        i = n.find("div.row"), jQuery(this).each(function() {
            jQuery(i[a]).append(jQuery(this)), s++, s == t ? (jQuery(this).addClass("right"), a++, s = 0) : jQuery(this).addClass("clear")
        }), i.each(function() {
            jQuery(this).css({
                display: "block"
            })
        });
        var l = function() {
            i.each(function() {
                var e = jQuery(this),
                    t = jQuery(this).find("div.contentPanel"),
                    i = -1;
                e.height("auto"), jQuery(".contentPanel").show(), jQuery(window).width() > _maxNarrowWidth && (t.each(function() {
                    0 > i ? i = jQuery(this).height() : jQuery(this).height() > i && (i = jQuery(this).height())
                }), i > 0 && e.height(i))
            })
        };
        jQuery(window).resize(function() {
            l(), windowResizeActions()
        })
    })
}

function drawnPromoImages() {
    jQuery(".promo").each(function() {
        var e = jQuery(this),
            t = e.find(".text h3 a").attr("href");
        e.find(".image").removeAttr("style"), e.find("img").removeAttr("style"), e.find(".image a").attr("href", t)
    })
}

function search(e, t) {
    np = parseInt(e) + 1, pp = parseInt(e) - 1, jQuery("#fb-results, .searchnav, #searchmessage").children().remove(), jQuery(".searchnav").hide().html(), jQuery("#fb-wrapper").before('<img style="border:0; width:auto; display:block; margin:0 auto;" src="http://www.gla.ac.uk/1t4/generic/images/ajax-loader.gif" id="loader" />'), url = "http://www.gla.ac.uk/feeds/findasupervisor/?q=" + t + "&page=" + e, 0 != jQuery("#supervisorsearch").length && jQuery.getJSON(url, function(i) {
        if (pages = i.searchdetails.pages, 0 == i.searchdetails.people) return jQuery("#loader").remove(), jQuery("#searchmessage").html("<p>No results found</p>"), !1;
        jQuery.each(i.results, function(e) {
            image = null === i.results[e].image ? "http://www.gla.ac.uk/1t4/generic/images/avatar.jpg" : i.results[e].image, org = null === i.results[e].org ? " " : i.results[e].org, role = null === i.results[e].role ? " " : i.results[e].role, phone = null === i.results[e].phone ? " " : i.results[e].phone, email = null === i.results[e].email ? " " : i.results[e].email, null !== i.results[e].name && (entry = '<li><div class="imagetext"><div class="imgwrap"><a href="' + i.results[e].url + '"><img src="' + image + '" /></a></div><span class="names"><h3><a href="' + i.results[e].url + '">' + i.results[e].name + "</a></h3></span><h5>" + org + "</h5><h6>" + role + '</h6><p><a href="mailto:' + email + '">' + email + '</a></p><div style="clear:both;"></div></div></li>', jQuery("#loader").remove(), jQuery(".searchnav").show(), jQuery("#fb-results").append(entry))
        });
        var n = pages;
        if (1 != pages)
            for (var a = new Array; n > 0;) n--, a.push('<li><a href="#" class="page ' + n + '" data-page="' + n + '">' + (n + 1) + "</a></li>");
        a.reverse(), jQuery.each(a, function(e, t) {
            jQuery(".searchnav").append(t)
        });
        var s = '<li><a href="#" class="next" data-page="' + np + '">next</a></li>',
            o = '<li><a href="#" class="prev" data-page="' + pp + '">prev</a></li>';
        1 != np && np < pages ? (jQuery(".searchnav").prepend(o), jQuery(".searchnav").append(s)) : np >= pages && 1 != np ? jQuery(".searchnav").prepend(o) : np < pages && jQuery(".searchnav").append(s), jQuery(".next, .prev, .page").click(function() {
            return jQuery("html, body").animate({
                scrollTop: 0
            }, 0), e = jQuery(this).attr("data-page"), jQuery.bbq.pushState({
                search: t,
                page: e
            }), !1
        });
        var r = "." + e;
        return jQuery(r).addClass("navactive"), jQuery(".searchnav li:last-child").addClass("last-item"), jQuery(".imgwrap").each(function() {
            var e = parseInt(jQuery(this).find("img").height());
            180 > e && jQuery(this).find("img").css({
                "border-bottom": "5px solid #fff"
            })
        }), !1
    })
}

function searchSups() {
    p = 0;
    var e = jQuery("#supervisorsearch").val();
    return e ? void jQuery.bbq.pushState({
        search: e,
        page: p
    }) : !1
}
var _contingency = 165,
    _maxMediumWidth = 850,
    _maxNarrowWidth = 665,
    _uiTabPanelPlugInRemoveClass = "ui-tabs-hide",
    _backgroundImagePositionConst = -305,
    serverbase = window.location.protocol + "//" + window.location.hostname;
Xtensible = function() {
    xtensible = this, xtensible.slidesArray = [], xtensible.newBlock = !1, xtensible.showNav = !0, xtensible.autoRotate = "", xtensible.addedClasses = "", xtensible.setcontainer = function() {
        xtensible.carouselStart = '<div class="responsiveContent xtensibleCarousel contentPanel clear ' + xtensible.addedClasses + '"><div class="blockTextAndImage generic flexContainer"> <div class="flexslider ' + xtensible.autoRotate + '"><ul class="rotatingPanel slides">', xtensible.carouselStartNarrow = '<div class="responsiveContent xtensibleCarousel xtensibleNarrow contentPanel singleContentElement "><div class="blockTextAndImage generic flexContainer"> <div class="flexslider ' + xtensible.autoRotate + '"><ul class="rotatingPanel slides">', xtensible.carouselEnd = '</ul></div></div><div class="controls right clearfix"></div></div>'
    }, xtensible.setup = function() {
        jQuery(".slide-data").each(function() {
            "autorotate" === jQuery(this).data("autorotate") && (xtensible.autoRotate = "autorotate", xtensible.showNav = !1), "slideshow" === jQuery(this).data("type") && (xtensible.addedClasses = "xtensibleSlideshow", xtensible.showNav = !0);
            var e = jQuery(this).next().attr("class");
            if (xtensible.slidesArray.push('<li class="xli">' + jQuery(this).html() + "</li>"), "slide-data" == e || (xtensible.setcontainer(), jQuery(xtensible.carouselStart + '<li class="replaceLi"></li>' + xtensible.carouselEnd).insertAfter(this), xtensible.newBlock = !0), xtensible.newBlock) {
                var t = xtensible.slidesArray.join("");
                xtensible.slidesArray = [], jQuery(".replaceLi").replaceWith(t), xtensible.newBlock = !1, xtensible.autoRotate = ""
            }
        }), jQuery(".slide-data-narrow").each(function() {
            "autorotate" === jQuery(this).data("autorotate") && (xtensible.autoRotate = "autorotate");
            var e = jQuery(this).next().attr("class");
            if (xtensible.slidesArray.push("<li>" + jQuery(this).html() + "</li>"), "slide-data-narrow" == e || (xtensible.setcontainer(), jQuery(xtensible.carouselStartNarrow + '<li class="replaceLi"></li>' + xtensible.carouselEnd).insertAfter(this), xtensible.newBlock = !0), xtensible.newBlock) {
                var t = xtensible.slidesArray.join("");
                xtensible.slidesArray = [], jQuery(".replaceLi").replaceWith(t), xtensible.newBlock = !1, xtensible.autoRotate = ""
            }
        }), jQuery(".slide-data, .slide-data-narrow").remove(), jQuery(".xtensibleCarousel .flexslider").each(function() {
            goslide = jQuery(this).hasClass("autorotate") ? !0 : !1, jQuery(this).flexslider({
                controlNav: !0,
                slideshow: goslide,
                pauseOnAction: !1,
                slideshowSpeed: 6e3,
                animationSpeed: 300,
                animation: "slide",
                touch: !0,
                easing: "swing",
                pauseOnAction: !0,
                pauseOnHover: !0,
                controlsContainer: ".pageCarouselBlock .controls",
                useCSS: !1,
                before: function() {
                    jQuery(".jwplayer").each(function() {
                        "slideshow_content" == jQuery(this).parent().attr("class") && (jwid = jQuery(this).attr("id"), jwplayer(jwid).stop())
                    })
                }
            })
        }), xtensible.showNav || (jQuery(".flex-direction-nav").hide(), jQuery(".xtensibleCarousel").hover(function() {
            jQuery(".flex-direction-nav").fadeIn("fast")
        }, function() {
            jQuery(".flex-direction-nav").fadeOut("fast")
        }))
    }
};
var Analytics = function() {
        analytic = this, analytic.label, analytic.action, analytic.category, analytic.trackEvent = function(e, t, i) {
            ga("send", "event", i, t, e)
        }, analytic.accordion = function() {
            jQuery(".hidenextdiv").length > 0 && jQuery(".hidenextdiv").click(function() {
                jQuery(this).data("clicked") || (analytic.category = location.href.split("/")[3], analytic.label = location.href, analytic.action = jQuery(this).children("a").text(), analytic.trackEvent(analytic.category, analytic.action, analytic.label), jQuery(this).data("clicked", "true"))
            })
        }
    },
    SiteStyle = function() {
        sitestyle = this, sitestyle.siteclasses = {
            collegeofmedicalveterinaryandlifesciences: "mvls",
            collegeofarts: "arts",
            collegeofscienceandengineering: "scieng",
            collegeofsocialsciences: "socsci",
            dentalschool: "mvls",
            schoolofcomputingscience: "scieng",
            schoolofcriticalstudies: "arts",
            schoolofcultureandcreativearts: "arts",
            schoolofgeographicalandearthsciences: "scieng",
            schoolofmodernlanguagesandcultures: "arts",
            schoolofeducation: "socsci",
            schoolofengineering: "scieng",
            schoolofhumanitiessgoilnandaonnachdan: "arts",
            schoolofinterdisciplinarystudies: "socsci",
            schooloflaw: "socsci",
            schoolofmedicine: "mvls",
            schoolofphysicsandastronomy: "scieng",
            schoolofsocialandpoliticalsciences: "socsci",
            instituteofcancersciences: "mvls",
            instituteofcardiovascularandmedicalsciences: "mvls",
            instituteofhealthandwellbeing: "mvls",
            instituteofinfectionimmunityandinflammation: "mvls",
            internal: "internal",
            undergraduate: "undergraduate",
            postgraduate: "postgraduate",
            research: "research"
        }, sitestyle.sitecusts = {
            mvls: {
                fullname: "the College of Medical, Veterinary and Life Sciences",
                link: "http://www.gla.ac.uk/mvls"
            },
            socsci: {
                fullname: "the College of Social Sciences",
                link: "http://www.gla.ac.uk/colleges/socialsciences/"
            },
            scieng: {
                fullname: "the College of Science and Engineering",
                link: "http://www.gla.ac.uk/colleges/scienceengineering/"
            },
            arts: {
                fullname: "the College of Arts",
                link: "http://www.gla.ac.uk/colleges/arts/"
            },
            internal: {
                fullname: "University Services",
                link: "http://www.gla.ac.uk/services"
            }
        }, sitestyle.setColours = function(e) {
            jQuery(".sectionHeader, .aside, .promo, .textsplash, #sp_staffphoto").addClass(e)
        }, sitestyle.setLinks = function(e) {
            sitestyle.sitecusts[e] && jQuery("#contactlinksul").append('<li><a href="' + sitestyle.sitecusts[e].link + '">Part of ' + sitestyle.sitecusts[e].fullname + "</a></li>")
        }, sitestyle.getColours = function() {
            switch (jQuery(".breadcrumbTop ul li:nth-child(2)").text().replace(/[, ]+/g, "").toLowerCase()) {
                case "development":
                    var e = jQuery(".breadcrumbTop ul li:nth-child(3)").text().replace(/[, |]+/g, "").toLowerCase();
                    break;
                case "myglasgowstaff":
                    jQuery("#stPageId1").html('<a href="http://www.gla.ac.uk/services">Services A-Z</a>');
                    var e = "internal";
                    break;
                case "servicesa-z":
                    var e = "internal",
                        t = jQuery(".breadcrumbTop ul li:nth-child(3)").text().replace(/[, |]+/g, "").toLowerCase();
                    "sport&recreation" == t && jQuery("body").after('<style media="screen" type="text/css">@import "http://www.gla.ac.uk/0t4/students/styles/extra/sportrec.css";</style>'), "library" == t && (ga("create", "UA-35592069-1", "auto"), ga("send", "pageview"));
                    break;
                case "undergraduatedegreeprogrammes":
                    var e = "undergraduate";
                    break;
                case "research":
                    var e = "research";
                    break;
                case "postgraduatetaughtdegreeprogrammes":
                    var e = "postgraduate";
                    break;
                case "schools":
                    var e = jQuery(".breadcrumbTop ul li:nth-child(3)").text().replace(/[, |]+/g, "").toLowerCase();
                    break;
                case "informationforcurrentstudents":
                    jQuery("#stPageId3").html('<a href="http://www.gla.ac.uk/students/azsearch/">Student services A-Z</a>')
            }
            sitestyle.setColours(sitestyle.siteclasses[e]), "colleges" != jQuery(".breadcrumbTop ul li:nth-child(2)").text().replace(/[, ]+/g, "").toLowerCase() && sitestyle.setLinks(sitestyle.siteclasses[e])
        }
    },
    openmapsize = function() {
        map_width = jQuery("#openmap").width(), map_height = 9 * map_width / 16, jQuery("#openmap").css({
            height: map_height + "px"
        })
    },
    tabHistory = function() {
        var e = jQuery("#tabs"),
            t = "ul.ui-tabs-nav a";
        e.tabs({
            event: "change"
        }), e.find(t).click(function() {
            var e = {};
            id = jQuery(this).closest("#tabs").attr("id"), idx = jQuery(this).parent().prevAll().length, e[id] = idx, jQuery.bbq.pushState(e)
        }), jQuery(window).bind("hashchange", function() {
            var i = jQuery.param.fragment();
            i = i.split("."), "d" == i[0], e.each(function() {
                var e = jQuery.bbq.getState(this.id, !0) || 0;
                jQuery(this).find(t).eq(e).triggerHandler("change"), jQuery(window).resize()
            })
        }), jQuery(window).trigger("hashchange")
    },
    kisWidget = function() {
        jQuery(".kis-data-popup") && jQuery(".kis-data-popup").magnificPopup({
            type: "iframe",
            closeOnContentClick: !0,
            callbacks: {
                open: function() {
                    jQuery(".mfp-content").css({
                        height: "150px",
                        width: "615px"
                    })
                }
            }
        })
    },
    fixF13 = function() {
        jQuery(".pop_close").css({
            display: "none"
        });
        var e = jQuery(".pop_cont_open").length;
        jQuery(".pop_cont_open").each(function(t) {
            jQuery(this).wrapInner('<a href="#f13-' + t + '-content" class="f13" />'), jQuery(this).next("div").attr("id", "f13-" + t + "-content").addClass("mfp-hide white-popup-block").css({
                "background-color": "#fff",
                padding: "2em",
                "max-width": "90%",
                "font-size": "1.4em"
            }), e == t + 1 && jQuery(".f13").magnificPopup({
                type: "inline"
            })
        })
    },
    runSupervisorSearch = function() {
        q = jQuery.bbq.getState("search"), p = jQuery.bbq.getState("page"), jQuery(window).width() < _maxNarrowWidth && jQuery("#findasupervisor").hide(), q && (jQuery("#supervisorsearch").val(q), search(p, q)), jQuery(window).bind("hashchange", function() {
            q = jQuery.bbq.getState("search"), p = jQuery.bbq.getState("page"), jQuery("#supervisorsearch").val(q), search(p, q)
        }), jQuery("#findasupervisor").click(function() {
            return searchSups(), !1
        }), jQuery("#supervisorsearch").keypress(function(e) {
            return 13 == e.which ? (searchSups(), !1) : void 0
        })
    },
    addThat = function() {
        jQuery(".share").click(function() {
            var e = {
                    facebook: "http://www.facebook.com/sharer.php?u=",
                    twitter: "http://twitter.com/share?url=",
                    googleplus: "https://plus.google.com/share?url="
                },
                t = window.location.href;
            return ga("send", "event", "share", jQuery(this).data("network"), t), window.open(e[jQuery(this).data("network")] + t, "", "width=600,height=400"), !1
        })
    },
    shortbread = function() {
        var e = jQuery(".breadcrumbTop ul li").length;
        if (e > 3) {
            var t = jQuery(".breadcrumbTop ul li:nth-child(3)");
            "Taught degree programmes A-Z" == t.text() && t.hide()
        }
        e > 5 && jQuery(".breadcrumbTop ul li").each(function(t) {
            t >= 3 && t != e - 1 && (3 == t && jQuery(this).after('<li id="shortbread"><a href="">...</a></li>'), jQuery(this).hide())
        }), jQuery("#shortbread").click(function() {
            return jQuery(".breadcrumbTop ul li").show(), jQuery(this).hide(), !1
        })
    },
    hideNextDiv = function() {
        jQuery(".sp_content").length > 0 && (jQuery("div .ep_view_page h2").addClass("hidenextdiv").wrapInner('<a href="#"></a>'), jQuery("div .ep_view_page").append('<a name="final_anchor"></a>'), jQuery("div .ep_view_page h2").each(function() {
            jQuery(this).nextUntil("a").wrapAll('<div  class="accordianhidden">')
        })), jQuery.fn.hidenextdiv = function() {
            this.each(function() {
                jQuery(this).next("div").hide(), jQuery("a", this).addClass("opendegree")
            });
            return jQuery(this).click(function() {
                return jQuery(this).next("div").slideToggle("fast"), jQuery("a", this).toggleClass("opendegree").toggleClass("closedegree"), !1
            }), this
        }, jQuery(".hidenextdiv:first").before('<div id="expandallwrapper"><div id="expandalldiv"></div></div>'), jQuery("#expandalldiv").click(function() {
            jQuery(this).data("clicked") || (analytic = new Analytics, analytic.category = location.href.split("/")[3], analytic.label = location.href, analytic.action = "expand all", analytic.trackEvent(analytic.category, analytic.action, analytic.label), jQuery(this).data("clicked", "true")), jQuery(this).data("expanded") ? (jQuery(this).removeClass("expandedall").data("expanded", !1), jQuery(".accordianhidden").slideUp("fast"), jQuery(".hidenextdiv").removeClass("expanded")) : (jQuery(this).addClass("expandedall").data("expanded", !0), jQuery(".accordianhidden").slideDown("fast"), jQuery(".hidenextdiv").addClass("expanded"))
        })
    },
    publications = function() {
        jQuery(".ep_view_jump_to a").click(function() {
            return loc = jQuery(this).attr("href").replace("#", ""), jQuery("html, body").animate({
                scrollTop: jQuery("a[name='" + loc + "']").offset().top + "px"
            }, {
                duration: 500,
                easing: "swing"
            }), !1
        }), jQuery("#pubsbydate").hide(), jQuery("#pubsbytype").show(), jQuery("#showpubsbytype").addClass("currentPubSel"), jQuery("#showpubsbytype").click(function() {
            return jQuery("#showpubsbytype").addClass("currentPubSel"), jQuery("#showpubsbydate").removeClass("currentPubSel"), jQuery("#pubsbytype").show(), jQuery("#pubsbydate").hide(), !1
        }), jQuery("#showpubsbydate").click(function() {
            return jQuery("#showpubsbytype").removeClass("currentPubSel"), jQuery("#showpubsbydate").addClass("currentPubSel"), jQuery("#pubsbytype").hide(), jQuery("#pubsbydate").show(), !1
        })
    },
    ugFix = function() {
        jQuery("#oldcoursenav").length > 0 && !jQuery("#coursenav li").length && jQuery("#oldcoursenav").hide(), jQuery(".tile_section_nav li").each(function() {
            0 == jQuery(this).children("a").length && jQuery(this).hide()
        })
    },
    windowResizeActions = function() {
        if (openmapsize(), postitionDropDownMenu(), IsResponsivePage()) {
            var e = jQuery(".links"),
                t = jQuery(".rightCol"),
                i = jQuery(".maincontent");
            jQuery(window).width() < _maxNarrowWidth ? (jQuery(".splashimage").hide(), jQuery("#pageContent").height(getDropDownListPageContentHeight()), i.parent().find(".maincontent").index() > i.parent().find(".rightCol").index() && t.insertAfter(i), e.each(function() {
                jQuery(this).addClass("repos").insertAfter(jQuery(this).next(".maincontent"))
            })) : (jQuery("#pageContent").removeClass("alteredHeight"), jQuery(".tabHideNextDiv").removeClass("closeTab"), jQuery("ul.menu").hide(), t.insertAfter(jQuery(".rightColAnchor")), jQuery(".repos").each(function() {
                jQuery(this).removeClass("repos").insertBefore(jQuery(this).prev(".maincontent"))
            })), jQuery(".dropdownButton").each(jQuery(window).width() >= _maxMediumWidth ? function() {
                jQuery(this).removeClass("open"), jQuery(this).parent("div").first().find("ul").show()
            } : function() {
                jQuery(this).hasClass("open") || jQuery(this).parent("div").first().find("ul").hide()
            })
        }
        if (setPageHeight(), IsResponsivePage()) {
            jQuery(".reponsiveContent .flexContainer").removeAttr("style"), jQuery(".pageCarouselBlock .rotatingPanel li .image img").removeAttr("style"), jQuery(".blockCarousel .rotatingPanel li .image img").css({
                width: "100%",
                height: "auto"
            }), jQuery(".homeCarousel .rotatingPanel li .image img").css({
                width: "100%",
                height: "auto"
            }), jQuery(".inlineTextAndImage .flexslider li .image").removeAttr("style");
            var n = jQuery(".inlineTextAndImage .flexslider li .image img");
            n.length > 0 && jQuery(".inlineTextAndImage .flexslider li .image img").css({
                height: n[0].naturalHeight,
                width: n[0].naturalWidth
            }), jQuery(".inlineTextAndImage .flexslider li .text").removeAttr("style")
        }
        if (drawnPromoImages(), drawNewsAndEventNav(), window.location.hash && "#d" == window.location.hash.split(".")[0]) {
            {
                jQuery(".sectionHeader h1").outerHeight()
            }
            jQuery(".sectionHeader").css({
                "margin-top": "110px"
            })
        }
        IsResponsivePage() && (jQuery("#tabs").length > 0 && setViewStateForContentTab(), jQuery(window).width() >= _maxNarrowWidth && (jQuery(".splashimage").show(), jQuery(".ui-tabs-panel").removeAttr("style"))), pgtDropAdj()
    },
    staffprofile = function() {
        staff = this, staff.staffphoto = jQuery("#sp_staffphoto"), staff.staffphotosrc = staff.staffphoto.find("img"), staff.postaladdress = jQuery("#sp_postaladdress"), staff.accordions = jQuery(".sp_content > .hidenextdiv"), staff.defaultStyle = function() {
            staff.staffphoto.addClass(staff.staffphotosrc.width() <= staff.staffphotosrc.height() ? "portrait" : "landscape")
        }, staff.accordion = function() {
            var e = staff.accordions.length;
            if (1 >= e) {
                var t = staff.accordions.find("a").text();
                staff.accordions.find("a").remove(), staff.accordions.html(t), staff.accordions.unbind("click").removeClass("hidenextdiv").removeClass("expanded").next().show().removeClass("accordianhidden"), jQuery("#expandallwrapper").remove()
            }
        }, staff.moveContent = function() {
            (0 != staff.staffphoto.length || 0 != staff.postaladdress.length) && (jQuery(window).width() < 665 ? (staff.staffphoto.hide(), staff.postaladdress.hide(), 0 == jQuery("#staffphotosm").length && staff.staffphoto.html() && jQuery(".maincontent:first").prepend('<div id="staffphotosm">' + staff.staffphoto.html() + "</div>"), 0 == jQuery("#postaladdresssm").length && 0 != jQuery("#sp_postaladdress").text().length && jQuery("#sp_contactInfo").after('<div id="postaladdresssm">' + staff.postaladdress.html() + "</div>")) : (staff.staffphoto.show(), staff.postaladdress.show(), jQuery("#staffphotosm").remove(), jQuery("#postaladdresssm").remove()))
        }, staff.moveContent()
    },
    loadScripts = function(e, t, i) {
        if (load = this, load.script = e, load.classes = t, load.checkLoaded = function() {
                for (var e = document.getElementsByTagName("script"), t = !1, i = 0; i < e.length; i++) null != e[i].getAttribute("src") && e[i].getAttribute("src").split("/")[6] === load.script && (t = !0);
                return t ? !0 : !1
            }, !load.checkLoaded()) {
            var n = !1;
            jQuery.each(load.classes, function(e) {
                jQuery(load.classes[e]).length > 0 && (n = !0)
            }), n && jQuery.getScript(serverbase + "/1t4/generic/scripts/" + load.script, function() {
                "" != i && setTimeout(function() {
                    i()
                }, 100)
            })
        }
    },
    survey = function() {
        jQuery.cookie("_so") || jQuery.get(serverbase + "/feeds/survey/", function(e) {
            "false" != e && (jQuery("#pageHeader").before('<div id="survey"><div id="surveyoptout"><a id="optout" href="#">x</a></div><p><a href="http://www.surveyexpression.com/Survey.aspx?id=2f3091d9-2f61-4b05-a1b4-5a01a5815930" target="blank">Help us to improve our website by answering a few quick questions: you\'ll be done in under three minutes.</a></p></div>'), jQuery("#optout").click(function() {
                return jQuery("#survey").slideUp("fast"), jQuery.cookie("_so", !0, {
                    expires: 7300
                }), !1
            }))
        })
    },
    imgCaptions = function() {
        jQuery(".maincontent img").each(function() {
            if ("" != jQuery(this).attr("title") && "undefined" != typeof jQuery(this).attr("title")) {
                var e = jQuery(this).attr("class"),
                    t = jQuery(this).width();
                "right" === e ? jQuery(this).wrap('<div class="imgright" />') : "left" === e && jQuery(this).wrap('<div class="imgleft" />'), jQuery(this).after('<div style="width:' + t + 'px" class="caption">' + jQuery(this).attr("title") + "</div>")
            }
        }), jQuery(window).resize(function() {
            jQuery(".caption").each(function() {
                jQuery(this).width(jQuery(this).prev("img").width())
            })
        })
    };
jQuery(function() {
        if (loadScripts("video.js", [".largeplayer", ".smallplayer", ".popupplayer", ".playlist", ".youtubeplaylist", ".mp3"], ""), jQuery(".heading_opener").click(function() {
                if (jQuery(this).next(".content_opener").find(".jwplayer ").length > 0 && jQuery(this).next(".content_opener").find(".mp3_wrapper ").length > 0) {
                    var e = jQuery(this).next(".content_opener").find(".jwplayer ").attr("id"),
                        t = jQuery(this).next(".content_opener").width();
                    jwplayer(e).resize(t, 40)
                }
            }), jQuery(".contentPanel").hide(), setcolours = new SiteStyle, setcolours.getColours(), alternateRows(), jQuery(".pullquote").wrapInner('<div style="padding:5%" />'), xcarousel = new Xtensible, xcarousel.setup(), jQuery(".xtensibleCarousel .rotatingPanel a img").css({
                width: "100%",
                height: "auto"
            }), jQuery(".xtensibleCarousel .rotatingPanel .text, .xtensibleCarousel .flexContainer").css({
                height: "auto"
            }), jQuery(".xtensibleCarousel .flexContainer").removeAttr("style"), jQuery(".responsiveContent").css("position", "relative"), jQuery(".blockCarousel .rotatingPanel li .image img").css({
                width: "100%",
                height: "auto"
            }), jQuery(".homeCarousel .rotatingPanel li .image img").css({
                width: "100%",
                height: "auto"
            }), jQuery(".inlineTextAndImage .flexslider li .image").removeAttr("style"), jQuery(".inlineTextAndImage .flexslider li .text").removeAttr("style"), analytics = new Analytics, analytics.accordion(), addThat(), imgCaptions(), jQuery("#map").length > 0 && openmapsize(), tabHistory(), kisWidget(), fixF13(), shortbread(), hideNextDiv(), jQuery(".hidenextdiv").hidenextdiv(), jQuery(".hidenextdiv").mouseup(function() {
                jQuery(this).toggleClass("expanded")
            }), pgtDrop(), pgtDropAdj(), jQuery(".open-popup-alumni").length > 0 && jQuery(".posttabs").after("<h2>Featured Alumni</h2>"), jQuery(".open-popup-alumni").magnificPopup({}), publications(), ugFix(), 0 != jQuery("#supervisorsearch").length && runSupervisorSearch(), jQuery("#sNav ul ul").each(function() {
                jQuery(this).parent("li").first().addClass("open")
            }), jQuery("#sNav .currentsection").each(function() {
                jQuery(this).parent("li").first().hasClass("open") || jQuery(this).parent("li").first().addClass("open")
            }), clearOnEnter(), generateDropDownListNav(), jQuery(".newsAndEvents .events").hide(), jQuery(".newsAndEventsNav li#news").addClass("active"), drawNewsAndEventNav(), jQuery(".newsAndEventsNav li").mouseup(function() {
                return jQuery(".newsAndEventsNav li").removeClass("active"), jQuery(this).addClass("active"), jQuery(".newsAndEvents .list").hide(), jQuery(".newsAndEvents ." + jQuery(this).attr("id")).show(), !1
            }), IsResponsivePage() && window.addEventListener("orientationchange", DeviceOrientationChangeEvent), jQuery(".staffDetails p").removeAttr("style"), jQuery(".staffDetails img").removeAttr("style"), jQuery(".imagePanel .image img").removeAttr("style"), jQuery("#refinebysubjectform #refinebysubjectselect").change(function() {
                return StringIsNullOrEmpty(jQuery(this).val()) ? !1 : void jQuery("#refinebysubjectform").submit()
            }), jQuery(".refinebysubjectselect").change(function() {
                return StringIsNullOrEmpty(jQuery(this).val()) ? !1 : void jQuery(this).parentsUntil("form").parent().submit()
            }), jQuery(".relatedprogrammesselect").change(function() {
                return StringIsNullOrEmpty(jQuery(this).val()) ? !1 : void jQuery(this).parentsUntil("form").parent().submit()
            }), jQuery("#jquerylist").listnav({
                includeNums: !1
            }), jQuery(".jquerylist").listnav({
                includeNums: !1
            }), jQuery(".ln-letters a:visible:last").addClass("ln-last"), jQuery("#tabs").length > 0) {
            jQuery("#tabs ul:first").children("li").each(function() {
                var e = jQuery(this).children("a").attr("href");
                jQuery(e).prepend("<h2>" + jQuery(this).children("a").text() + "</h2>")
            }), setViewStateForContentTab(), jQuery(".hidenextdiv").hidenextdiv(), jQuery(".hidenextstoriesdiv").hidenextdiv();
            var e = jQuery("#tabs").find(".ui-tabs-panel").first();
            e.addClass("first")
        }
        if (jQuery(".sp_content").length > 0) {
            var t = new staffprofile;
            t.defaultStyle(), t.accordion(), jQuery(window).resize(function() {
                t.defaultStyle(), t.moveContent()
            })
        }
        var i = jQuery(".singleContentElement");
        if (i.length > 1)
            for (var n = 0; n < i.length; n++) n % 2 == 1 && (i[n].className += " right");
        window.addEventListener && (window.addEventListener("error", function(e) {
            ga("send", "event", "JavaScript Error", e.message, e.filename + ":  " + e.lineno)
        }), jQuery(document).ajaxError(function(e, t, i) {
            ga("send", "event", "Ajax error", i.url, e.result)
        }))
    }), jQuery(window).load(function() {
        jQuery("#newsContainer li").each(function() {
            jQuery(this).find(".datetime").insertAfter(jQuery(this).find(".text h4"))
        }), jQuery(".responsiveContent").css("position", "relative"), drawnPromoImages(), initPromoGrid(), setPageHeight(), setTimeout(function() {
            forceResize(), setPageHeight()
        }, 500), jQuery(".links .contentPanel").show()
    }),
    function(e) {
        e.fn.listnav = function(t) {
            var i = e.extend({}, e.fn.listnav.defaults, t),
                n = ["_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "-"],
                a = !1;
            return i.prefixes = e.map(i.prefixes, function(e) {
                return e.toLowerCase()
            }), this.each(function() {
                function t() {
                    if (f.append(p()), m = e(".ln-letters", f).slice(0, 1), i.showCounts && (g = e(".ln-letter-count", f).slice(0, 1)), o(), c(), i.flagDisabled && l(), u(), i.includeAll || h.show(), i.includeAll || e(".all", m).remove(), i.includeNums || e("._", m).remove(), i.includeOther || e(".-", m).remove(), e(":last", m).addClass("ln-last"), e.cookie && null != i.cookieName) {
                        var t = e.cookie(i.cookieName);
                        null != t && (i.initLetter = t)
                    }
                    if ("" != i.initLetter) a = !0, e("." + i.initLetter.toLowerCase(), m).slice(0, 1).click();
                    else if (i.includeAll) e(".all", m).addClass("ln-selected");
                    else
                        for (var s = i.includeNums ? 0 : 1; s < n.length; s++)
                            if (w[n[s]] > 0) {
                                a = !0, e("." + n[s], m).slice(0, 1).click();
                                break
                            }
                }

                function s() {
                    g.css({
                        top: 0
                    })
                }

                function o() {
                    var t, n, a, s, o = i.prefixes.length > 0;
                    e(h).children().each(function() {
                        s = e(this), n = "", t = e.trim(s.text()).toLowerCase(), "" != t && (o && (a = t.split(" "), a.length > 1 && e.inArray(a[0], i.prefixes) > -1 && (n = a[1].charAt(0), r(n, s, !0))), n = t.charAt(0), r(n, s))
                    })
                }

                function r(e, t, i) {
                    /\W/.test(e) && (e = "-"), isNaN(e) || (e = "_"), t.addClass("ln-" + e), void 0 == w[e] && (w[e] = 0), w[e] ++, i || jQuery++
                }

                function l() {
                    for (var t = 0; t < n.length; t++) void 0 == w[n[t]] && e("." + n[t], m).addClass("ln-disabled")
                }

                function c() {
                    h.append('<li class="ln-no-match" style="display:none">' + i.noMatchText + "</li>")
                }

                function d(t) {
                    if (e(t).hasClass("all")) return jQuery;
                    var i = w[e(t).attr("class").split(" ")[0]];
                    return void 0 != i ? i : 0
                }

                function u() {
                    i.showCounts && f.mouseover(function() {
                        s()
                    }), i.showCounts && (e("a", m).mouseover(function() {
                        var t = e(this).position().left,
                            i = e(this).outerWidth({
                                margin: !0
                            }) - 1 + "px",
                            n = d(this);
                        g.css({
                            left: t,
                            width: i
                        }).text(n).show()
                    }), e("a", m).mouseout(function() {
                        g.hide()
                    })), e("a", m).click(function() {
                        e("a.ln-selected", m).removeClass("ln-selected");
                        var t = e(this).attr("class").split(" ")[0];
                        if ("all" == t) h.children().each(function() {
                            e(this).show(), e(this).index() == jQuery && isdefined("curvyCorners") && curvyCorners.redraw()
                        }), h.children(".ln-no-match").hide(), b = !0;
                        else {
                            b ? (h.children().hide(), b = !1) : "" != y && h.children(".ln-" + y).hide();
                            var n = d(this);
                            n > 0 ? (h.children(".ln-no-match").hide(), h.children(".ln-" + t).each(function() {
                                e(this).show(), e(this).index() == e(".ln-" + t + ":last").index() && isdefined("curvyCorners") && curvyCorners.redraw()
                            })) : h.children(".ln-no-match").show(), y = t
                        }
                        return e.cookie && null != i.cookieName && e.cookie(i.cookieName, t), e(this).addClass("ln-selected"), e(this).blur(), a || null == i.onClick ? a = !1 : i.onClick(t), !1
                    })
                }

                function p() {
                    for (var e = [], t = 1; t < n.length; t++) 0 == e.length && e.push('<a class="all" href="#">ALL</a><a class="_" href="#">0-9</a>'), e.push('<a class="' + n[t] + '" href="#">' + ("-" == n[t] ? "..." : n[t].toUpperCase()) + "</a>");
                    return '<div class="ln-letters">' + e.join("") + "</div>" + (i.showCounts ? '<div class="ln-letter-count" style="display:none; position:absolute; top:0; left:0; width:20px;">0</div>' : "")
                }
                var f, h, m, g, v;
                v = this.id, f = e("#" + v + "-nav"), h = e(this);
                var w = {},
                    jQuery = 0,
                    b = !0,
                    y = "";
                t()
            })
        }, e.fn.listnav.defaults = {
            initLetter: "",
            includeAll: !0,
            incudeOther: !1,
            includeNums: !0,
            flagDisabled: !0,
            noMatchText: "No matching entries",
            showCounts: !0,
            cookieName: null,
            onClick: null,
            prefixes: []
        }
    }(jQuery),
    function(e) {
        var t, i, n, a, s, o, r, l = "Close",
            c = "BeforeClose",
            d = "AfterClose",
            u = "BeforeAppend",
            p = "MarkupParse",
            f = "Open",
            h = "Change",
            m = "mfp",
            g = "." + m,
            v = "mfp-ready",
            w = "mfp-removing",
            jQuery = "mfp-prevent-close",
            b = function() {},
            y = !!window.jQuery,
            x = e(window),
            C = function(e, i) {
                t.ev.on(m + e + g, i)
            },
            k = function(t, i, n, a) {
                var s = document.createElement("div");
                return s.className = "mfp-" + t, n && (s.innerHTML = n), a ? i && i.appendChild(s) : (s = e(s), i && s.appendTo(i)), s
            },
            I = function(i, n) {
                t.ev.triggerHandler(m + i, n), t.st.callbacks && (i = i.charAt(0).toLowerCase() + i.slice(1), t.st.callbacks[i] && t.st.callbacks[i].apply(t, e.isArray(n) ? n : [n]))
            },
            S = function() {
                (t.st.focus ? t.content.find(t.st.focus).eq(0) : t.wrap).focus()
            },
            P = function(i) {
                return i === r && t.currTemplate.closeBtn || (t.currTemplate.closeBtn = e(t.st.closeMarkup.replace("%title%", t.st.tClose)), r = i), t.currTemplate.closeBtn
            },
            _ = function() {
                e.magnificPopup.instance || (t = new b, t.init(), e.magnificPopup.instance = t)
            },
            A = function(i) {
                if (!e(i).hasClass(jQuery)) {
                    var n = t.st.closeOnContentClick,
                        a = t.st.closeOnBgClick;
                    if (n && a) return !0;
                    if (!t.content || e(i).hasClass("mfp-close") || t.preloader && i === t.preloader[0]) return !0;
                    if (i === t.content[0] || e.contains(t.content[0], i)) {
                        if (n) return !0
                    } else if (a && e.contains(document, i)) return !0;
                    return !1
                }
            },
            T = function() {
                var e = document.createElement("p").style,
                    t = ["ms", "O", "Moz", "Webkit"];
                if (void 0 !== e.transition) return !0;
                for (; t.length;)
                    if (t.pop() + "Transition" in e) return !0;
                return !1
            };
        b.prototype = {
            constructor: b,
            init: function() {
                var i = navigator.appVersion;
                t.isIE7 = -1 !== i.indexOf("MSIE 7."), t.isIE8 = -1 !== i.indexOf("MSIE 8."), t.isLowIE = t.isIE7 || t.isIE8, t.isAndroid = /android/gi.test(i), t.isIOS = /iphone|ipad|ipod/gi.test(i), t.supportsTransition = T(), t.probablyMobile = t.isAndroid || t.isIOS || /(Opera Mini)|Kindle|webOS|BlackBerry|(Opera Mobi)|(Windows Phone)|IEMobile/i.test(navigator.userAgent), n = e(document.body), a = e(document), t.popupsCache = {}
            },
            open: function(i) {
                var n;
                if (i.isObj === !1) {
                    t.items = i.items.toArray(), t.index = 0;
                    var s, r = i.items;
                    for (n = 0; n < r.length; n++)
                        if (s = r[n], s.parsed && (s = s.el[0]), s === i.el[0]) {
                            t.index = n;
                            break
                        }
                } else t.items = e.isArray(i.items) ? i.items : [i.items], t.index = i.index || 0;
                if (t.isOpen) return void t.updateItemHTML();
                t.types = [], o = "", t.ev = i.mainEl && i.mainEl.length ? i.mainEl.eq(0) : a, i.key ? (t.popupsCache[i.key] || (t.popupsCache[i.key] = {}), t.currTemplate = t.popupsCache[i.key]) : t.currTemplate = {}, t.st = e.extend(!0, {}, e.magnificPopup.defaults, i), t.fixedContentPos = "auto" === t.st.fixedContentPos ? !t.probablyMobile : t.st.fixedContentPos, t.st.modal && (t.st.closeOnContentClick = !1, t.st.closeOnBgClick = !1, t.st.showCloseBtn = !1, t.st.enableEscapeKey = !1), t.bgOverlay || (t.bgOverlay = k("bg").on("click" + g, function() {
                    t.close()
                }), t.wrap = k("wrap").attr("tabindex", -1).on("click" + g, function(e) {
                    A(e.target) && t.close()
                }), t.container = k("container", t.wrap)), t.contentContainer = k("content"), t.st.preloader && (t.preloader = k("preloader", t.container, t.st.tLoading));
                var l = e.magnificPopup.modules;
                for (n = 0; n < l.length; n++) {
                    var c = l[n];
                    c = c.charAt(0).toUpperCase() + c.slice(1), t["init" + c].call(t)
                }
                I("BeforeOpen"), t.st.showCloseBtn && (t.st.closeBtnInside ? (C(p, function(e, t, i, n) {
                    i.close_replaceWith = P(n.type)
                }), o += " mfp-close-btn-in") : t.wrap.append(P())), t.st.alignTop && (o += " mfp-align-top"), t.wrap.css(t.fixedContentPos ? {
                    overflow: t.st.overflowY,
                    overflowX: "hidden",
                    overflowY: t.st.overflowY
                } : {
                    top: x.scrollTop(),
                    position: "absolute"
                }), (t.st.fixedBgPos === !1 || "auto" === t.st.fixedBgPos && !t.fixedContentPos) && t.bgOverlay.css({
                    height: a.height(),
                    position: "absolute"
                }), t.st.enableEscapeKey && a.on("keyup" + g, function(e) {
                    27 === e.keyCode && t.close()
                }), x.on("resize" + g, function() {
                    t.updateSize()
                }), t.st.closeOnContentClick || (o += " mfp-auto-cursor"), o && t.wrap.addClass(o);
                var d = t.wH = x.height(),
                    u = {};
                if (t.fixedContentPos && t._hasScrollBar(d)) {
                    var h = t._getScrollbarSize();
                    h && (u.paddingRight = h)
                }
                t.fixedContentPos && (t.isIE7 ? e("body, html").css("overflow", "hidden") : u.overflow = "hidden");
                var m = t.st.mainClass;
                return t.isIE7 && (m += " mfp-ie7"), m && t._addClassToMFP(m), t.updateItemHTML(), I("BuildControls"), e("html").css(u), t.bgOverlay.add(t.wrap).prependTo(document.body), t._lastFocusedEl = document.activeElement, setTimeout(function() {
                    t.content ? (t._addClassToMFP(v), S()) : t.bgOverlay.addClass(v), a.on("focusin" + g, function(i) {
                        return i.target === t.wrap[0] || e.contains(t.wrap[0], i.target) ? void 0 : (S(), !1)
                    })
                }, 16), t.isOpen = !0, t.updateSize(d), I(f), i
            },
            close: function() {
                t.isOpen && (I(c), t.isOpen = !1, t.st.removalDelay && !t.isLowIE && t.supportsTransition ? (t._addClassToMFP(w), setTimeout(function() {
                    t._close()
                }, t.st.removalDelay)) : t._close())
            },
            _close: function() {
                I(l);
                var i = w + " " + v + " ";
                if (t.bgOverlay.detach(), t.wrap.detach(), t.container.empty(), t.st.mainClass && (i += t.st.mainClass + " "), t._removeClassFromMFP(i), t.fixedContentPos) {
                    var n = {
                        paddingRight: ""
                    };
                    t.isIE7 ? e("body, html").css("overflow", "") : n.overflow = "", e("html").css(n)
                }
                a.off("keyup" + g + " focusin" + g), t.ev.off(g), t.wrap.attr("class", "mfp-wrap").removeAttr("style"), t.bgOverlay.attr("class", "mfp-bg"), t.container.attr("class", "mfp-container"), t.st.showCloseBtn && (!t.st.closeBtnInside || t.currTemplate[t.currItem.type] === !0) && t.currTemplate.closeBtn && t.currTemplate.closeBtn.detach(), t._lastFocusedEl && e(t._lastFocusedEl).focus(), t.currItem = null, t.content = null, t.currTemplate = null, t.prevHeight = 0, I(d)
            },
            updateSize: function(e) {
                if (t.isIOS) {
                    var i = document.documentElement.clientWidth / window.innerWidth,
                        n = window.innerHeight * i;
                    t.wrap.css("height", n), t.wH = n
                } else t.wH = e || x.height();
                t.fixedContentPos || t.wrap.css("height", t.wH), I("Resize")
            },
            updateItemHTML: function() {
                var i = t.items[t.index];
                t.contentContainer.detach(), t.content && t.content.detach(), i.parsed || (i = t.parseEl(t.index));
                var n = i.type;
                if (I("BeforeChange", [t.currItem ? t.currItem.type : "", n]), t.currItem = i, !t.currTemplate[n]) {
                    var a = t.st[n] ? t.st[n].markup : !1;
                    I("FirstMarkupParse", a), t.currTemplate[n] = a ? e(a) : !0
                }
                s && s !== i.type && t.container.removeClass("mfp-" + s + "-holder");
                var o = t["get" + n.charAt(0).toUpperCase() + n.slice(1)](i, t.currTemplate[n]);
                t.appendContent(o, n), i.preloaded = !0, I(h, i), s = i.type, t.container.prepend(t.contentContainer), I("AfterChange")
            },
            appendContent: function(e, i) {
                t.content = e, e ? t.st.showCloseBtn && t.st.closeBtnInside && t.currTemplate[i] === !0 ? t.content.find(".mfp-close").length || t.content.append(P()) : t.content = e : t.content = "", I(u), t.container.addClass("mfp-" + i + "-holder"), t.contentContainer.append(t.content)
            },
            parseEl: function(i) {
                var n = t.items[i],
                    a = n.type;
                if (n = n.tagName ? {
                        el: e(n)
                    } : {
                        data: n,
                        src: n.src
                    }, n.el) {
                    for (var s = t.types, o = 0; o < s.length; o++)
                        if (n.el.hasClass("mfp-" + s[o])) {
                            a = s[o];
                            break
                        }
                    n.src = n.el.attr("data-mfp-src"), n.src || (n.src = n.el.attr("href"))
                }
                return n.type = a || t.st.type || "inline", n.index = i, n.parsed = !0, t.items[i] = n, I("ElementParse", n), t.items[i]
            },
            addGroup: function(e, i) {
                var n = function(n) {
                    n.mfpEl = this, t._openClick(n, e, i)
                };
                i || (i = {});
                var a = "click.magnificPopup";
                i.mainEl = e, i.items ? (i.isObj = !0, e.off(a).on(a, n)) : (i.isObj = !1, i.delegate ? e.off(a).on(a, i.delegate, n) : (i.items = e, e.off(a).on(a, n)))
            },
            _openClick: function(i, n, a) {
                var s = void 0 !== a.midClick ? a.midClick : e.magnificPopup.defaults.midClick;
                if (s || 2 !== i.which && !i.ctrlKey && !i.metaKey) {
                    var o = void 0 !== a.disableOn ? a.disableOn : e.magnificPopup.defaults.disableOn;
                    if (o)
                        if (e.isFunction(o)) {
                            if (!o.call(t)) return !0
                        } else if (x.width() < o) return !0;
                    i.type && (i.preventDefault(), t.isOpen && i.stopPropagation()), a.el = e(i.mfpEl), a.delegate && (a.items = n.find(a.delegate)), t.open(a)
                }
            },
            updateStatus: function(e, n) {
                if (t.preloader) {
                    i !== e && t.container.removeClass("mfp-s-" + i), !n && "loading" === e && (n = t.st.tLoading);
                    var a = {
                        status: e,
                        text: n
                    };
                    I("UpdateStatus", a), e = a.status, n = a.text, t.preloader.html(n), t.preloader.find("a").on("click", function(e) {
                        e.stopImmediatePropagation()
                    }), t.container.addClass("mfp-s-" + e), i = e
                }
            },
            _addClassToMFP: function(e) {
                t.bgOverlay.addClass(e), t.wrap.addClass(e)
            },
            _removeClassFromMFP: function(e) {
                this.bgOverlay.removeClass(e), t.wrap.removeClass(e)
            },
            _hasScrollBar: function(e) {
                return (t.isIE7 ? a.height() : document.body.scrollHeight) > (e || x.height())
            },
            _parseMarkup: function(t, i, n) {
                var a;
                n.data && (i = e.extend(n.data, i)), I(p, [t, i, n]), e.each(i, function(e, i) {
                    if (void 0 === i || i === !1) return !0;
                    if (a = e.split("_"), a.length > 1) {
                        var n = t.find(g + "-" + a[0]);
                        if (n.length > 0) {
                            var s = a[1];
                            "replaceWith" === s ? n[0] !== i[0] && n.replaceWith(i) : "img" === s ? n.is("img") ? n.attr("src", i) : n.replaceWith('<img src="' + i + '" class="' + n.attr("class") + '" />') : n.attr(a[1], i)
                        }
                    } else t.find(g + "-" + e).html(i)
                })
            },
            _getScrollbarSize: function() {
                if (void 0 === t.scrollbarSize) {
                    var e = document.createElement("div");
                    e.id = "mfp-sbm", e.style.cssText = "width: 99px; height: 99px; overflow: scroll; position: absolute; top: -9999px;", document.body.appendChild(e), t.scrollbarSize = e.offsetWidth - e.clientWidth, document.body.removeChild(e)
                }
                return t.scrollbarSize
            }
        }, e.magnificPopup = {
            instance: null,
            proto: b.prototype,
            modules: [],
            open: function(t, i) {
                return _(), t = t ? e.extend(!0, {}, t) : {}, t.isObj = !0, t.index = i || 0, this.instance.open(t)
            },
            close: function() {
                return e.magnificPopup.instance && e.magnificPopup.instance.close()
            },
            registerModule: function(t, i) {
                i.options && (e.magnificPopup.defaults[t] = i.options), e.extend(this.proto, i.proto), this.modules.push(t)
            },
            defaults: {
                disableOn: 0,
                key: null,
                midClick: !1,
                mainClass: "",
                preloader: !0,
                focus: "",
                closeOnContentClick: !1,
                closeOnBgClick: !0,
                closeBtnInside: !0,
                showCloseBtn: !0,
                enableEscapeKey: !0,
                modal: !1,
                alignTop: !1,
                removalDelay: 0,
                fixedContentPos: "auto",
                fixedBgPos: "auto",
                overflowY: "auto",
                closeMarkup: '<button title="%title%" type="button" class="mfp-close">&times;</button>',
                tClose: "Close (Esc)",
                tLoading: "Loading..."
            }
        }, e.fn.magnificPopup = function(i) {
            _();
            var n = e(this);
            if ("string" == typeof i)
                if ("open" === i) {
                    var a, s = y ? n.data("magnificPopup") : n[0].magnificPopup,
                        o = parseInt(arguments[1], 10) || 0;
                    s.items ? a = s.items[o] : (a = n, s.delegate && (a = a.find(s.delegate)), a = a.eq(o)), t._openClick({
                        mfpEl: a
                    }, n, s)
                } else t.isOpen && t[i].apply(t, Array.prototype.slice.call(arguments, 1));
            else i = e.extend(!0, {}, i), y ? n.data("magnificPopup", i) : n[0].magnificPopup = i, t.addGroup(n, i);
            return n
        };
        var E, N, O, z = "inline",
            H = function() {
                O && (N.after(O.addClass(E)).detach(), O = null)
            };
        e.magnificPopup.registerModule(z, {
            options: {
                hiddenClass: "hide",
                markup: "",
                tNotFound: "Content not found"
            },
            proto: {
                initInline: function() {
                    t.types.push(z), C(l + "." + z, function() {
                        H()
                    })
                },
                getInline: function(i, n) {
                    if (H(), i.src) {
                        var a = t.st.inline,
                            s = e(i.src);
                        if (s.length) {
                            var o = s[0].parentNode;
                            o && o.tagName && (N || (E = a.hiddenClass, N = k(E), E = "mfp-" + E), O = s.after(N).detach().removeClass(E)), t.updateStatus("ready")
                        } else t.updateStatus("error", a.tNotFound), s = e("<div>");
                        return i.inlineElement = s, s
                    }
                    return t.updateStatus("ready"), t._parseMarkup(n, {}, i), n
                }
            }
        });
        var L, B = "ajax",
            j = function() {
                L && n.removeClass(L)
            },
            M = function() {
                j(), t.req && t.req.abort()
            };
        e.magnificPopup.registerModule(B, {
            options: {
                settings: null,
                cursor: "mfp-ajax-cur",
                tError: '<a href="%url%">The content</a> could not be loaded.'
            },
            proto: {
                initAjax: function() {
                    t.types.push(B), L = t.st.ajax.cursor, C(l + "." + B, M), C("BeforeChange." + B, M)
                },
                getAjax: function(i) {
                    L && n.addClass(L), t.updateStatus("loading");
                    var a = e.extend({
                        url: i.src,
                        success: function(n, a, s) {
                            var o = {
                                data: n,
                                xhr: s
                            };
                            I("ParseAjax", o), t.appendContent(e(o.data), B), i.finished = !0, j(), S(), setTimeout(function() {
                                t.wrap.addClass(v)
                            }, 16), t.updateStatus("ready"), I("AjaxContentAdded")
                        },
                        error: function() {
                            j(), i.finished = i.loadError = !0, t.updateStatus("error", t.st.ajax.tError.replace("%url%", i.src))
                        }
                    }, t.st.ajax.settings);
                    return t.req = e.ajax(a), ""
                }
            }
        });
        var D, R = function(i) {
            if (i.data && void 0 !== i.data.title) return i.data.title;
            var n = t.st.image.titleSrc;
            if (n) {
                if (e.isFunction(n)) return n.call(t, i);
                if (i.el) return i.el.attr(n) || ""
            }
            return ""
        };
        e.magnificPopup.registerModule("image", {
            options: {
                markup: '<div class="mfp-figure"><div class="mfp-close"></div><div class="mfp-img"></div><div class="mfp-bottom-bar"><div class="mfp-title"></div><div class="mfp-counter"></div></div></div>',
                cursor: "mfp-zoom-out-cur",
                titleSrc: "title",
                verticalFit: !0,
                tError: '<a href="%url%">The image</a> could not be loaded.'
            },
            proto: {
                initImage: function() {
                    var e = t.st.image,
                        i = ".image";
                    t.types.push("image"), C(f + i, function() {
                        "image" === t.currItem.type && e.cursor && n.addClass(e.cursor)
                    }), C(l + i, function() {
                        e.cursor && n.removeClass(e.cursor), x.off("resize" + g)
                    }), C("Resize" + i, t.resizeImage), t.isLowIE && C("AfterChange", t.resizeImage)
                },
                resizeImage: function() {
                    var e = t.currItem;
                    if (e && e.img && t.st.image.verticalFit) {
                        var i = 0;
                        t.isLowIE && (i = parseInt(e.img.css("padding-top"), 10) + parseInt(e.img.css("padding-bottom"), 10)), e.img.css("max-height", t.wH - i)
                    }
                },
                _onImageHasSize: function(e) {
                    e.img && (e.hasSize = !0, D && clearInterval(D), e.isCheckingImgSize = !1, I("ImageHasSize", e), e.imgHidden && (t.content && t.content.removeClass("mfp-loading"), e.imgHidden = !1))
                },
                findImageSize: function(e) {
                    var i = 0,
                        n = e.img[0],
                        a = function(s) {
                            D && clearInterval(D), D = setInterval(function() {
                                return n.naturalWidth > 0 ? void t._onImageHasSize(e) : (i > 200 && clearInterval(D), i++, 3 === i ? a(10) : 40 === i ? a(50) : 100 === i && a(500), void 0)
                            }, s)
                        };
                    a(1)
                },
                getImage: function(i, n) {
                    var a = 0,
                        s = function() {
                            i && (i.img[0].complete ? (i.img.off(".mfploader"), i === t.currItem && (t._onImageHasSize(i), t.updateStatus("ready")), i.hasSize = !0, i.loaded = !0, I("ImageLoadComplete")) : (a++, 200 > a ? setTimeout(s, 100) : o()))
                        },
                        o = function() {
                            i && (i.img.off(".mfploader"), i === t.currItem && (t._onImageHasSize(i), t.updateStatus("error", r.tError.replace("%url%", i.src))), i.hasSize = !0, i.loaded = !0, i.loadError = !0)
                        },
                        r = t.st.image,
                        l = n.find(".mfp-img");
                    if (l.length) {
                        var c = document.createElement("img");
                        c.className = "mfp-img", i.img = e(c).on("load.mfploader", s).on("error.mfploader", o), c.src = i.src, l.is("img") && (i.img = i.img.clone()), i.img[0].naturalWidth > 0 && (i.hasSize = !0)
                    }
                    return t._parseMarkup(n, {
                        title: R(i),
                        img_replaceWith: i.img
                    }, i), t.resizeImage(), i.hasSize ? (D && clearInterval(D), i.loadError ? (n.addClass("mfp-loading"), t.updateStatus("error", r.tError.replace("%url%", i.src))) : (n.removeClass("mfp-loading"), t.updateStatus("ready")), n) : (t.updateStatus("loading"), i.loading = !0, i.hasSize || (i.imgHidden = !0, n.addClass("mfp-loading"), t.findImageSize(i)), n)
                }
            }
        });
        var F, W = function() {
            return void 0 === F && (F = void 0 !== document.createElement("p").style.MozTransform), F
        };
        e.magnificPopup.registerModule("zoom", {
            options: {
                enabled: !1,
                easing: "ease-in-out",
                duration: 300,
                opener: function(e) {
                    return e.is("img") ? e : e.find("img")
                }
            },
            proto: {
                initZoom: function() {
                    var e, i = t.st.zoom,
                        n = ".zoom";
                    if (i.enabled && t.supportsTransition) {
                        var a, s, o = i.duration,
                            r = function(e) {
                                var t = e.clone().removeAttr("style").removeAttr("class").addClass("mfp-animated-image"),
                                    n = "all " + i.duration / 1e3 + "s " + i.easing,
                                    a = {
                                        position: "fixed",
                                        zIndex: 9999,
                                        left: 0,
                                        top: 0,
                                        "-webkit-backface-visibility": "hidden"
                                    },
                                    s = "transition";
                                return a["-webkit-" + s] = a["-moz-" + s] = a["-o-" + s] = a[s] = n, t.css(a), t
                            },
                            d = function() {
                                t.content.css("visibility", "visible")
                            };
                        C("BuildControls" + n, function() {
                            if (t._allowZoom()) {
                                if (clearTimeout(a), t.content.css("visibility", "hidden"), e = t._getItemToZoom(), !e) return void d();
                                s = r(e), s.css(t._getOffset()), t.wrap.append(s), a = setTimeout(function() {
                                    s.css(t._getOffset(!0)), a = setTimeout(function() {
                                        d(), setTimeout(function() {
                                            s.remove(), e = s = null, I("ZoomAnimationEnded")
                                        }, 16)
                                    }, o)
                                }, 16)
                            }
                        }), C(c + n, function() {
                            if (t._allowZoom()) {
                                if (clearTimeout(a), t.st.removalDelay = o, !e) {
                                    if (e = t._getItemToZoom(), !e) return;
                                    s = r(e)
                                }
                                s.css(t._getOffset(!0)), t.wrap.append(s), t.content.css("visibility", "hidden"), setTimeout(function() {
                                    s.css(t._getOffset())
                                }, 16)
                            }
                        }), C(l + n, function() {
                            t._allowZoom() && (d(), s && s.remove(), e = null)
                        })
                    }
                },
                _allowZoom: function() {
                    return "image" === t.currItem.type
                },
                _getItemToZoom: function() {
                    return t.currItem.hasSize ? t.currItem.img : !1
                },
                _getOffset: function(i) {
                    var n;
                    n = i ? t.currItem.img : t.st.zoom.opener(t.currItem.el || t.currItem);
                    var a = n.offset(),
                        s = parseInt(n.css("padding-top"), 10),
                        o = parseInt(n.css("padding-bottom"), 10);
                    a.top -= e(window).scrollTop() - s;
                    var r = {
                        width: n.width(),
                        height: (y ? n.innerHeight() : n[0].offsetHeight) - o - s
                    };
                    return W() ? r["-moz-transform"] = r.transform = "translate(" + a.left + "px," + a.top + "px)" : (r.left = a.left, r.top = a.top), r
                }
            }
        });
        var q = "iframe",
            U = "//about:blank",
            Z = function(e) {
                if (t.currTemplate[q]) {
                    var i = t.currTemplate[q].find("iframe");
                    i.length && (e || (i[0].src = U), t.isIE8 && i.css("display", e ? "block" : "none"))
                }
            };
        e.magnificPopup.registerModule(q, {
            options: {
                markup: '<div class="mfp-iframe-scaler"><div class="mfp-close"></div><iframe class="mfp-iframe" src="//about:blank" frameborder="0" allowfullscreen></iframe></div>',
                srcAction: "iframe_src",
                patterns: {
                    youtube: {
                        index: "youtube.com",
                        id: "v=",
                        src: "//www.youtube.com/embed/%id%?autoplay=1"
                    },
                    vimeo: {
                        index: "vimeo.com/",
                        id: "/",
                        src: "//player.vimeo.com/video/%id%?autoplay=1"
                    },
                    gmaps: {
                        index: "//maps.google.",
                        src: "%id%&output=embed"
                    }
                }
            },
            proto: {
                initIframe: function() {
                    t.types.push(q), C("BeforeChange", function(e, t, i) {
                        t !== i && (t === q ? Z() : i === q && Z(!0))
                    }), C(l + "." + q, function() {
                        Z()
                    })
                },
                getIframe: function(i, n) {
                    var a = i.src,
                        s = t.st.iframe;
                    e.each(s.patterns, function() {
                        return a.indexOf(this.index) > -1 ? (this.id && (a = "string" == typeof this.id ? a.substr(a.lastIndexOf(this.id) + this.id.length, a.length) : this.id.call(this, a)), a = this.src.replace("%id%", a), !1) : void 0
                    });
                    var o = {};
                    return s.srcAction && (o[s.srcAction] = a), t._parseMarkup(n, o, i), t.updateStatus("ready"), n
                }
            }
        });
        var Q = function(e) {
                var i = t.items.length;
                return e > i - 1 ? e - i : 0 > e ? i + e : e
            },
            K = function(e, t, i) {
                return e.replace(/%curr%/gi, t + 1).replace(/%total%/gi, i)
            };
        e.magnificPopup.registerModule("gallery", {
            options: {
                enabled: !1,
                arrowMarkup: '<button title="%title%" type="button" class="mfp-arrow mfp-arrow-%dir%"></button>',
                preload: [0, 2],
                navigateByImgClick: !0,
                arrows: !0,
                tPrev: "Previous (Left arrow key)",
                tNext: "Next (Right arrow key)",
                tCounter: "%curr% of %total%"
            },
            proto: {
                initGallery: function() {
                    var i = t.st.gallery,
                        n = ".mfp-gallery",
                        s = Boolean(e.fn.mfpFastClick);
                    return t.direction = !0, i && i.enabled ? (o += " mfp-gallery", C(f + n, function() {
                        i.navigateByImgClick && t.wrap.on("click" + n, ".mfp-img", function() {
                            return t.items.length > 1 ? (t.next(), !1) : void 0
                        }), a.on("keydown" + n, function(e) {
                            37 === e.keyCode ? t.prev() : 39 === e.keyCode && t.next()
                        })
                    }), C("UpdateStatus" + n, function(e, i) {
                        i.text && (i.text = K(i.text, t.currItem.index, t.items.length))
                    }), C(p + n, function(e, n, a, s) {
                        var o = t.items.length;
                        a.counter = o > 1 ? K(i.tCounter, s.index, o) : ""
                    }), C("BuildControls" + n, function() {
                        if (t.items.length > 1 && i.arrows && !t.arrowLeft) {
                            var n = i.arrowMarkup,
                                a = t.arrowLeft = e(n.replace(/%title%/gi, i.tPrev).replace(/%dir%/gi, "left")).addClass(jQuery),
                                o = t.arrowRight = e(n.replace(/%title%/gi, i.tNext).replace(/%dir%/gi, "right")).addClass(jQuery),
                                r = s ? "mfpFastClick" : "click";
                            a[r](function() {
                                t.prev()
                            }), o[r](function() {
                                t.next()
                            }), t.isIE7 && (k("b", a[0], !1, !0), k("a", a[0], !1, !0), k("b", o[0], !1, !0), k("a", o[0], !1, !0)), t.container.append(a.add(o))
                        }
                    }), C(h + n, function() {
                        t._preloadTimeout && clearTimeout(t._preloadTimeout), t._preloadTimeout = setTimeout(function() {
                            t.preloadNearbyImages(), t._preloadTimeout = null
                        }, 16)
                    }), C(l + n, function() {
                        a.off(n), t.wrap.off("click" + n), t.arrowLeft && s && t.arrowLeft.add(t.arrowRight).destroyMfpFastClick(), t.arrowRight = t.arrowLeft = null
                    }), void 0) : !1
                },
                next: function() {
                    t.direction = !0, t.index = Q(t.index + 1), t.updateItemHTML()
                },
                prev: function() {
                    t.direction = !1, t.index = Q(t.index - 1), t.updateItemHTML()
                },
                goTo: function(e) {
                    t.direction = e >= t.index, t.index = e, t.updateItemHTML()
                },
                preloadNearbyImages: function() {
                    var e, i = t.st.gallery.preload,
                        n = Math.min(i[0], t.items.length),
                        a = Math.min(i[1], t.items.length);
                    for (e = 1; e <= (t.direction ? a : n); e++) t._preloadItem(t.index + e);
                    for (e = 1; e <= (t.direction ? n : a); e++) t._preloadItem(t.index - e)
                },
                _preloadItem: function(i) {
                    if (i = Q(i), !t.items[i].preloaded) {
                        var n = t.items[i];
                        n.parsed || (n = t.parseEl(i)), I("LazyLoad", n), "image" === n.type && (n.img = e('<img class="mfp-img" />').on("load.mfploader", function() {
                            n.hasSize = !0
                        }).on("error.mfploader", function() {
                            n.hasSize = !0, n.loadError = !0, I("LazyLoadError", n)
                        }).attr("src", n.src)), n.preloaded = !0
                    }
                }
            }
        });
        var G = "retina";
        e.magnificPopup.registerModule(G, {
                options: {
                    replaceSrc: function(e) {
                        return e.src.replace(/\.\w+jQuery/, function(e) {
                            return "@2x" + e
                        })
                    },
                    ratio: 1
                },
                proto: {
                    initRetina: function() {
                        if (window.devicePixelRatio > 1) {
                            var e = t.st.retina,
                                i = e.ratio;
                            i = isNaN(i) ? i() : i, i > 1 && (C("ImageHasSize." + G, function(e, t) {
                                t.img.css({
                                    "max-width": t.img[0].naturalWidth / i,
                                    width: "100%"
                                })
                            }), C("ElementParse." + G, function(t, n) {
                                n.src = e.replaceSrc(n, i)
                            }))
                        }
                    }
                }
            }),
            function() {
                var t = 1e3,
                    i = "ontouchstart" in window,
                    n = function() {
                        x.off("touchmove" + s + " touchend" + s)
                    },
                    a = "mfpFastClick",
                    s = "." + a;
                e.fn.mfpFastClick = function(a) {
                    return e(this).each(function() {
                        var o, r = e(this);
                        if (i) {
                            var l, c, d, u, p, f;
                            r.on("touchstart" + s, function(e) {
                                u = !1, f = 1, p = e.originalEvent ? e.originalEvent.touches[0] : e.touches[0], c = p.clientX, d = p.clientY, x.on("touchmove" + s, function(e) {
                                    p = e.originalEvent ? e.originalEvent.touches : e.touches, f = p.length, p = p[0], (Math.abs(p.clientX - c) > 10 || Math.abs(p.clientY - d) > 10) && (u = !0, n())
                                }).on("touchend" + s, function(e) {
                                    n(), u || f > 1 || (o = !0, e.preventDefault(), clearTimeout(l), l = setTimeout(function() {
                                        o = !1
                                    }, t), a())
                                })
                            })
                        }
                        r.on("click" + s, function() {
                            o || a()
                        })
                    })
                }, e.fn.destroyMfpFastClick = function() {
                    e(this).off("touchstart" + s + " click" + s), i && x.off("touchmove" + s + " touchend" + s)
                }
            }()
    }(window.jQuery || window.Zepto);