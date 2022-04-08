---
title: Rick Wash CV
layout: master
---

Rick Wash
=========

### Associate Professor
Department of Media and Information  
*Michigan State University*

#### Office
404 Wilson Rd #402  
402 Communication Arts and Sciences  
Michigan State University  
East Lansing, MI 48824  
(517) 355-2381  
<wash@msu.edu>

#### Home
2712 Kittanset Dr  
Okemos, MI 48864   
(734) 730-1188  
<rick.wash@gmail.com>

### Appointments

* 2016-Present: Associate Professor (with tenure), *Michigan State University*.
    * Department of Media and Information
* 2015-2016: Associate Professor (with tenure), *Michigan State University*.
    * School of Journalism (51%)
    * Department of Media and Information (49%)  
* 2010-2015: Assistant Professor, *Michigan State University*.
    * School of Journalism (51%)
    * Department of Media and Information (49%)  (formerly Telecommunication, Information Studies, and Media)
* 2009-2010: Visiting Assistant Professor, *Michigan State University*.
    * Department of Telecommunications, Information Studies, and Media

### Education

* *PhD*, School of Information, *University of Michigan*. 2009
* *Masters of Science*, Computer Science. *University of Michigan*. 2005
* *Bachelors of Science*, Computer Science. *Case Western Reserve University*. 2002

### Awarded Research Grants

* *National Science Foundation*, "Workshop on Trustworthy Algorithmic Decision-Making". [CNS-1748381](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1748381), Emilee Rader, PI.  **Rick Wash, Co-PI**. 2017-2018. Budget $93,909
* *National Science Foundation*, "SaTC: CORE: Small: Using Stories to Improve Computer Security Decision Making". [CNS-1714126](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1714126), **Rick Wash, PI**. 2017-2020. Budget $515,987
    * REU Supplement 2019: $16,000
* *National Science Foundation*, "CAREER: Mental Models and Critical Mass: Shaping the Success of Online Communities." [IIS-1350253](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1350253), **Rick Wash, PI**. 2014-2019 Budget $489,678.
    * REU Supplement 2014: $16,000
    * REU Supplement 2015: $16,000
    * REU Supplement 2017: $16,000
* *National Science Foundation*, "TC:Collaborative Research:Small:Influencing Mental Models of Security." [CNS-1116544](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1116544), **Rick Wash, PI MSU**.  Emilee Rader, PI Northwestern. 2011-2014 Total Budget: $499,781; MSU Budget: $258,194
    * REU Supplement 2012: $16,000
    * REU Supplement 2013: $16,000
    * REU Supplement 2014: $16,000
    * REU Supplement 2015: $8,000
* *National Science Foundation*, "Socio-technical Design of Crowdfunding Websites." [CCF-1101266](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1101266), **Rick Wash, PI**. 2011-2014 Budget $399,511.
    * REU Supplement 2012: $16,000
    * REU Supplement 2013: $16,000
* *National Science Foundation*, "CT-ER: Incentive Centered Technology Design for Home User Security." [CNS 0716196](https://www.nsf.gov/awardsearch/showAward?AWD_ID=0716196), Jeffrey MacKie-Mason PI. 2007-2009. Budget: $200,000. **Rick Wash, Unofficial co-PI** 

<!--
#### Proposal Under Review


#### Declined Research Grant Proposals

* *MSU Strategic Partnership Grant*, "Measuring and Understanding Cyberterror and Extremism Using Open Source Data." Tom Holt, PI.  Steven Chermak, **Rick Wash**, Johannes Bauer, and Richard Enbody, Co-PIs. 2015.  Budget: $179,956
* *National Science Foundation*, "Personalizing Incentives to Support Social Media Contribution." Gary Hsieh, PI.  **Rick Wash, Co-PI**.  Budget $638,792
* *National Science Foundation*, "CAREER: Building Critical Mass in Online Communities." **Rick Wash, PI**. Budget $499,735
* *National Science Foundation*, "TWC SBE: Small: Security Inferences: Learning from Interfaces." **RIck Wash, PI**. Budget $499,533
-->

### Awards and Fellowships

* [SOUPS Impact Award](https://www.usenix.org/conference/soups2020/impact-award). Symposium on Usable Security and Privacy (SOUPS) 2020 (for significant impact on usable security and privacy research and practice) for paper "Folk Models of Home Computer Security"
* Google [Security and Privacy Research Award](https://www.blog.google/technology/safety-security/working-security-researchers-make-web-safer-everyone/) 2018
* *Gary M. Olson Outstanding PhD Student Award*. School of Information, University of Michigan. 2008
* National Science Foundation IGERT Fellowship. University of Michigan STIET program. 2002-2004

#### Best Paper type awards
* Honorable Mention Award. ACM Conference on Human Factors in Computing (CHI) 2018:
* Nominated for Best Paper. Human Factors and Ergonomics Society Annual meeting, 2014
* Distinguished Poster Award. Symposium on Usable Privacy and Security 2014
* Best Paper Honorable Mention (Top 5%), ACM Computer Supported Cooperative Work conference 2014 

Publications
------------

### Dissertation

* "Motivating Contributions for Home Computer Security." Rick Wash. University of Michigan, 2009.
    : Chair: Jeffrey K. MacKie-Mason
    : Committee: Judith Olson, Mark Ackerman, Brian Noble

### Journal Papers

{% for post in site.categories.journal %} {% capture pub %}
  {% include journal.md %}
  {% if post.link %} <{{post.link}}>{% endif %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endfor %}

### Conference Proceedings

{% for post in site.categories.conference %} {% capture pub %} 
  {% include conference.md %}
  {% if post.doi %} DOI [{{ post.doi }}](http://dx.doi.org/{{ post.doi }}) {% endif %} 
{% endcapture %} * {{ pub | strip_newlines | strip_html }}
{% endfor %}

### Book Chapters

{% for post in site.categories.bookchap %} {% capture pub %} 
  {% include bookchap.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endfor %}

### Articles for Non-Academic Audiences

{% for post in site.categories.magazine %} {% capture pub %} 
  {% include magazine.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endfor %}

### Workshop Papers

{% for post in site.categories.workshop %} {% capture pub %}
  {% include workshop.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endfor %}

### Working Papers

{% for post in site.categories.working %} {% capture pub %}
  {% include working.md %}
{% endcapture %} * {{ pub | strip_newlines }}
{% endfor %}


### Invited Talks

* Rick Wash, "[How People Detect Phishing Messages](https://blogs.mtu.edu/icc/2021/11/dr-rick-wash-msu-to-present-keynote-lecture-november-11/)". Talk at Michigan Technical University (November 2021)
* Rick Wash, "How to Catch a Phish." Talk for [MSU IT Cybersecurity Awareness Month](https://tech.msu.edu/news/2021/10/national-cybersecurity-awareness-month/) (2021)
* Rick Wash, "Detecting Phishing Messages." At Sonoma State University CS Colloquium (2021)
* Rick Wash, "Detecting Phishing." At MSU Extension All-Staff Meeting (2021)
* Rick Wash, "Detecting Phishing and Social Engineering." At MSU IT Security Forum (2021)
* Rick Wash, "Cybersecurity Gossip: Using Stories to Improve Security Decisions." At "Univeristy of Pittsburg, School of Computing and Information". (2018) 
* Rick Wash, "Cybersecurity Gossip: Using Stories to Improve Security Decisions." At "Univeristy of Maryland, iSchool". (2018) 
* Rick Wash, "The Role of Human Decisions in Computer Security Systems." At *Penn State University, College of Information Sciences and Technology". (2018)
* Rick Wash, "Cybersecurity Gossip: Using Stories to Improve Security Decisions." At the *U.S. Federal Trade Commission*. (2017)
* Rick Wash. "Understanding Everyday Decision Making." At *Indiana University, School of Informatics*. (2016)
* Rick Wash. "Understanding Everyday Decision Making." At *Syracuse University, School of Information Studies*. (2016)
* Rick Wash and Emilee Rader. "Influencing Mental Models of Security." At Lansing Torch Club, East Lansing, MI. (2014)
* Rick Wash. "Folk Security." At *Indiana University, School of Informatics*. (2013)
* Rick Wash. "Thinking and Talking About Security." At *Indiana University, School of Informatics*. (2012)
* Rick Wash. "Thinking and Talking About Security." At *Cornell University, Information Science Colloquium*. (2012)
* Rick Wash. "Socio-technical Influence on Behavior in Social Media." At *Michigan State University, School of Journalism and Department of Telecommunications, Information Studies, and Media*. (2010)
* Rick Wash. "Socio-technical Influence on Behavior in Social Media." At *University of North Carolina at Chapel Hill, School of Information and Library Science*. (2010)
* Rick Wash. "Socio-technical Influence on Behavior in Social Media." At *Northwestern University, SONIC lab*. (2010)
* Rick Wash.  "Is 'Social Tagging' an Oxymoron? Understanding Incentives on del.icio.us." At *Drexel University, the iSchool at Drexel*. (2009) 
* Rick Wash.  "Is 'Social Tagging' an Oxymoron? Understanding Incentives on del.icio.us." At *Michigan State University, Department of Telecommunication, Information Studies, and Media*. (2009) 
* Rick Wash.  "Is 'Social Tagging' an Oxymoron? Understanding Incentives on del.icio.us." At *Massachusetts Institute of Technology, Media Lab*. (2009) 
* Rick Wash.  "Is 'Social Tagging' an Oxymoron? Understanding Incentives on del.icio.us." At *Rutgers University, Department of Library and Information Science*. (2009)
* Rick Wash and Jeffrey MacKie-Mason. "Incentive-Centered Design for Information Security." At *DIMACS Workshop on Information Security Economics* (2007).
* Rick Wash and Jeffrey MacKie-Mason. "Incentive-Centered Design for Information Security." At *Ford Information Technology Seminar* (2007).
* Rick Wash. "The Economics of Malevolence in Cyberspace." (Mar. 2005). Invited Talk at *Case Western Reserve University*. 
* Rick Wash. "The Security of Trusted Computing." (February 2004). Invited Talk at *Case Western Reserve University*. 
* Rick Wash. "The Digital Millenium Copyright Act." (February 2002). Given at the *CWRU Chapter of the ACM*. 

### Patents

* US Patent #7,890,338: Method for Managing a Whitelist.  Inventors: Theodore C Loder, Marshall van Alstyne, Richard L Wash. Issued February 15, 2011

Teaching Experience
-------------------

### Classes Taught

#### Instructor of Record
* **Spring  2020**. MSU MI 250: Introduction to Applied Programming
* **Fall 2019**. MSU MI 250: Introduction to Applied Programming
* **Fall 2019**. MSU MI 220: *Methods for Understanding Users*
* **Spring 2019**. MSU MI 985: *Analysis for Media*
* **Fall 2018**. MSU MI 220: *Methods for Understanding Users*
* **Spring 2018**. MSU MI 985: *Analysis for Media*
* **Fall 2017**. MSU MI 220: *Methods for Understanding Users*
* **Spring 2017**. MSU MI 985: *Analysis for Media*
* **Fall 2016**. MSU MI 220: *Methods for Understanding Users*
* **Fall 2016**. MSU MI 491 / JRN 492: *Building Online Communities*
* **Spring 2016**. MSU MI 985: *Analysis for Media*
* **Spring 2016**. MSU JRN 821: *Social Media News and Information*
* **Fall 2015**. MSU TC 491 / JRN 492: *Building Online Communities*
* **Spring 2015**. MSU TC 985: *Analysis for Media*
* **Spring 2015**. MSU JRN 821: *Social Media News and Information*
* **Fall 2014**. MSU TC 491 / JRN 492: *Building Online Communities*
* **Spring 2014**. MSU TC 985: *Analysis for Media*
* **Spring 2014**. MSU TC 359: *Server-Side Web Development*
* **Fall 2013**. MSU CAS 992: *Special Topics: Big Data*
* **Spring 2013**. MSU TC 985: *Analysis for Media*
* **Spring 2013**. MSU JRN 821: *Social Media News and Information*
* **Fall 2012**. MSU TC 359: *Server-Side Web Development*
* **Spring 2012**. MSU TC 359: *Server-Side Web Development*
* **Spring 2012**. MSU TC 985: *Analysis for Media*
* **Fall 2011**. MSU CAS 992: *Special Topics: Large-Scale Data and Exploratory Data Analysis*
* **Spring 2011**. MSU JRN 492: *Special Topics: Computing and Journalism*
* **Spring 2011**. MSU TC 449: *Server-Side Web Development*
* **Fall 2010**. MSU TC 861: *Information Networks and Technologies*
* **Spring 2010**. MSU TC 449: *Server-Side Web Development*
* **Spring 2010**. MSU TC 458: *Project Management*

#### As Assistant
* Facilitator, "Getting Started: GSIs Teaching Graduate Students." GSI Teaching Orientation, University of Michigan. Fall 2007, Winter 2008, and Fall 2008 
* Graduate Student Instructor: SI 540 *Understanding Networked Computing*, School of Information, University of Michigan. Fall 2006. 
* Graduate Student Instructor: SI 502 *Choice and Decision Making*, School of Information, University of Michigan. Winter 2006. 
* Graduate Student Instructor: EECS 381 *Advanced Object Oriented Programming*, Electrical Engineering and Computer Science, University of Michigan. Fall 2004. 
* Teaching Assistant: ECES 381 *Intro to Operating Systems*, Computer Engineering and Science, Case Western Reserve University. Spring 2001. 
* Teaching Assistant: ENGR 101 *Intro to Computer Science*, College of Engineering, Case Western Reserve University. Fall 1999.

#### Independent Study Projects Supervised

* Ruth Shillair (PhD): Fall 2014
* Michael Friedman (PhD): Spring 2012
* Andrew Rockwell (UG): Spring 2012
* Jacob Solomon (PhD): Fall 2011
* Jeff Proulx (MA): Fall 2011
* Aaron Robinson (UG): Fall 2011
* Tor Bjornrud (PhD): Spring 2010

### Students Advised

#### Postdoctoral Researchers

* Kami Vaniea. 2012-2014  (Indiana University --> University of Edinborough)
* Norbert Nthala.  2019-2021 (Google)

#### PhD Students graduated as advisor

* Jacob Solomon.  MSU MIS.   2010-2015   (Postdoc at University of Michigan; now Athena Health)
* Chankyung Pak. MSU MIS.  2013-2018 (Postdoc at University of Amsterdam; now BNU-HKBU United International College in China)

#### PhD Advisor

* Megan Knittel. MSU IM. 2018-2020
* Chris Fennell. MSU IM. 2016-2020
* Yuyang Liang. MSU MIS. 2015-2016 (graduated)
* Jan-Hendrik Boehmer. MSU MIS. 2011-2013 (graduated)
* Laeeq Khan. MSU MIS. 2012-2013 (graduated)
* Tor Bjornrud. MSU MIS. 2011-2012

#### PhD Committee Member

* Adam Jenkins, University of Edinburgh. External Examiner (2021-2022)
* Dominik Neumann. MSU IM. 2017-2018 (graduated)
* Shaheen Kanthawala. MSU MIS. 2016-2018 (graduated)
* Travis Kadylak. MSU MIS. 2016-2019 (graduated)
* Julia DeCook. MSU MIS. 2015-2016 (graduated)
* Kendall Koning. MSU MIS. 2014-2018 (graduated)
* Eunsin Joo. MSU MIS. 2015-2017
* Yumi Jung. MSU MIS. 2014-2017 (graduated)
* Ruth Shillair. MSU MIS. 2014-2017
* Tian Cai. MSU MIS. 2014-2016
* Jan-Hendrik Boehmer. MSU MIS. 2013-2014 (graduated)
* Sang Yup Lee. MSU MIS. 2012-2014 (graduated)
* Wenjuan Ma. MSU MIS. 2012-2017 (graduated)
* Sonya Yan Song. MSU MIS. 2012-2015 (graduated)
* Ryan Feywin-Bliss. MSU MIS. 2011-2012
* Michael Friedman. MSU MIS. 2011-2013 (graduated)
* Brandon Brooks. MSU MIS. 2011-2015 (graduated)
* Jason Watson. UNC-Charlotte. 2011-2014 (graduated)
* Tor Bjornrud. MSU MIS. 2010-2011; became chair in 2011

#### MA Advisor

* Craig Tucker. MSU TC Masters Project. 2012 
* Ian Hewlett.  MSU TC Masters Thesis. 2012

#### MA Committee Member

<!-- * Benoit Bennot-Madin. MSU TC Masters Project. 2011 ? -->
* Maggie Vandura. MSU TC Masters Project. 2011
* Jeff Gillies. MSU Journalism Masters Thesis. 2011
* Xi (Mickey) Yue. MSU TC Masters Thesis. 2011 
* Chris Hamrick. MSU TC Masters Thesis. 2011
* Korey Scott. MSU TC Masters Project. 2010

#### Masters-level Research Assistants

* Janghee Cho. Spring 2018
* Andrew Osentoski. Fall 2015
* Benoit Bonnet-Madin. Fall 2011 
* Craig Tucker. Fall 2011 

#### Undergraduate Research Assistants

* Sophie Lamphier, MSU. Spring 2021
* Abrielle Mason, MSU. Fall 2019, Spring 2020
* Faye Kollig, MSU. Fall 2019, Spring 2020, <!-- professorial assistant --> Summer 2020, Fall 2020, Spring 2021
* Connor O'Rourke, MSU. Fall 2018. <!-- professorial assistant -->
* Daniel Khairallah, MSU. Summer 2018.
* Caitlyn Myers, MSU. Spring, Summer, Fall 2018.
* Julie Gerstley, MSU.  Summer 2017. <!-- Tulane -->
* Dottie Blyth, MSU. Summer 2017. <!-- North Carolina -->
* Nicholas Gilreath, MSU. Fall 2016, Spring 2017, Fall 2017, Spring 2018, Fall 2018.
* Robert Novak, MSU. Fall 2016, Spring 2017, Fall 2017, Spring 2018. 
* Jimmy Mkude, MSU. Fall 2016
* Nina Capuzzi, MSU. Spring 2016, Fall 2016, Spring 2017.
* Zac Wellmer, MSU. Fall 2015.
* Ruthie Berman, MSU. Summer 2015. <!-- Macalester -->
* Robert Plant Pinto Santos, MSU. Summer 2015. <!-- Miami (OH), Brazil -->
* Sean McNeil, MSU. Summer 2015. <!-- Cornell -->
* Ellen Light, MSU. Summer 2015. <!-- UW Madison -->
* Annika De Souza, MSU. Summer 2015. 
* Paul Rose, MSU. Fall 2014, Spring 2015.
* Meghan Huynh, MSU.  Fall 2014, Spring 2015, Fall 2015.
* Brandon Beasley, MSU. Summer 2014
* Stephanie Pena, MSU. Summer 2014 <!-- Michigan -->
* Lezlie Espana, MSU. Summer 2014 <!-- Wisconsin Lutheran -->
* Shiwani Bisht, MSU. Summer 2014 <!-- Cornell -->
* Nathan Klein, MSU. Summer 2014 <!-- Oberlin -->
* Kyle Kulesza, MSU. Spring 2014
* Tim Hasselbeck, MSU. Spring 2014
* Jallal Elhazzat, MSU. Spring 2014
* Scott Ruscinski, MSU. Fall 2013, Spring 2014
* Ruchira Ramani, MSU. Fall 2013
* Raymond Heldt, MSU. Summer 2013
* Katie Hoban, MSU. Summer 2013, Fall 2013, Spring 2014, Summer 2014
* Alexandra Hinck, MSU. Summer 2013  <!-- Beloit College -->
* Grayson Wright, MSU. Spring 2013, Fall 2013, Spring 2014
* Nick Saxton, MSU. Fall 2012, Spring 2013, Summer 2013, Fall 2013
* Tyler Olsen, MSU. Fall 2012, Spring 2013
* Leanarda Gregordi, MSU. Fall 2012
* Howard Akumiah, MSU. Fall 2012, Spring 2013
* Michelle Rizor, MSU. Fall 2012, Spring 2013, Fall 2013, Spring 2014
* Zack Girouard, MSU. Fall 2012, Spring 2013, Summer 2013
* Jake Wesorick, MSU. Summer 2012
* Sam Mills, MSU. Summer--Fall, 2012
* Alison Thierbach, MSU. Summer 2012 REU
* Kyle Safran, MSU. Summer 2012 REU, Fall 2012
* Nate Zemanek, MSU. Summer 2012 REU
* Kim Setili, MSU. Spring 2012, Summer 2012 REU
* Lauren McKown, MSU. Spring 2012-Summer 2012
* Mitchell Thelen, MSU. Spring 2012
* Andrew Rockwell, MSU. Spring 2012
* Aaron Robinson, MSU. Fall 2011
* Rachel Lipson. UMich NSF REU, Summer 2008

Scholarly Service
-----------------

### Service to the Research Community

*Symposium on Usable Security and Privacy (SOUPS)* Steering Committee. 2017-2023.  
*Journal of CyberSecurity* Area Editor, Anthropological and Cultural Studies.  Oxford University Press. 2015-present  
*IEEE Internet Computing* Guest Editor, Special Issue on Usable Privacy and Security.  IEEE Computing Society. 2016-2017.  
*Workshop on Trustworthy Algorithmic Decision-Making* 2017.  Co-organizer.  
*Symposium on Usable Privacy and Security* Program Committee Co-Chair 2022, 2023


Conference Program Committees:

* SOUPS (Symposium on Usable Privacy and Security): 2011, 2012, 2013, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 (PC Co-chair), 2023 (PC Co-Chair)
* WEIS (Workshop on Economics and Information Security): 2012, 2013
* CHI (ACM Conference on Computer-Human Interaction) Associate Chair: 2010 (Interaction Beyond the Individual subcommittee), 2019 (Security, Privacy and Visualization subcommittee)
* STAST (Workshop on Socio-Technical Aspects in Security and Trust): [2012](http://www.stast2012.uni.lu/), [2014](http://stast2014.uni.lu/), [2015](http://www.stast2015.uni.lu/), 2017
* CSCW (ACM Conference on Computer-Supported Cooperative Work) Associate Chair: 2013, 2015, 2020
* WikiSym: 2013 (track on open collaboration)
* USec (Workshop on Usable Security): 2014, 2016, 2017, 2018
* EuroUSec (European Workshop on Usable Security): 2016, 2017
* USENIX Security: 2022/2023

Other Committee Roles:
* *Symposium on Usable Privacy and Security* 2020 Karat student research award chair.
* I was Student Volunteer Coordinator for ACM E-Commerce 2006.  
* Member, Karat Outstanding PhD student award committee, SOUPS 2021

I was an external reviewer (panelist) for the NSF in 2011, 2012, 2014 (twice), 2015, 2016, 2017, 2019, and 2020.

I am an external expert consultant for:

* [CitizenLab Security Planner](https://securityplanner.org/)
* [Cyber Security Body of Knowledge](http://www.cybok.org) (Human Factors Knowledge Area reviewer) 

Reviewer for:

* Journal of Electronic Commerce
* ICIS 2006, 2011
* ACM E-Commerce 2007 & 2008
* CHI 2008, 2009, 2011, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020
* iConference 2008
* CSCW 2008, 2010,  2011, 2012, 2014, 2016, 2017 (online first), 2018, 2019
* WWW 2008
* ACM GROUP 2009.
* ICWSM 2013, 2014
* HCI Journal 2013, 2014
* SOUPS 2014
* IEEE Computer Security Foundations (CSF) 2014
* Computers and Security 2014
* ACM Transactions on Privacy and Security (TOPS) 2017, 2018
* American Economic Journal: Economic Policy 2018
* ACM Computing Surveys 2018, 2019
* ACM Transactions on Computer Human Interaction (TOCHI) 2021

### University Service

* MSU Social Media Seminar Series.  Organizer, Fall 2010, Fall 2011, Fall 2012
* MSU MIS PhD Spring Research Symposium.  Organizer and MC, Spring 2012, Spring 2013, Spring 2014, Fall 2015
* MSU Journalism Research Committee 2010-2016
* MSU TISM PhD Committee 2010-2011
* MSU TISM PhD Committee Chair 2011-2014
* MSU MIS PhD Program Steering Committee. 2011-2014
* MSU TISM Search Committee -- ICT4D. 2011-2012
* MSU JRN Search Committee -- Innovative Journalism. 2011-2012
* MSU TISM Search Committee -- Socio-Technical Researcher. 2012-2013
* MSU JRN Search Committee -- Innovative Journalism and Tech / Media Management and Econ. 2015-2016
* MSU MI Academic Program Review committee, 2015-2016
* MSU MI Search Committee Chair -- Human-Centered Technology. 2016-2017
* MSU IM PhD Program Review Committee -- 2017
* MSU Faculty Grievance Jurisdiction Appeal Panel -- 2017
* MSU MI Department PhD program re-vision committee -- 2017-2018
* MSU MI Search Committee. 2018-2019
* MSU MI Director of Doctoral Studies, 2020-2021
* MSU ComArtSci Research Advisory Board, 2021-
* MSU MI Annual Performance Reivew Committee 2022-


### Outreach

* Presented research on phishing to MSU Security Forum March 2021 <!-- ~100 attendees -->
* Prsented research on phihsing to MSU Extension All-Staff meeting in May 2021 <!-- 341 attendees -->
* Peer review committee for the CitizenLab Security Planner tool.
* Expert at the US Federal Trade Commission's Hearings on Competition and Consumer Protection in the 21st Century: <https://www.ftc.gov/news-events/events-calendar/ftc-hearing-competition-consumer-protection-21st-century-december-2018>

Previous Work Experience
------------------------

* *Cigital Labs*. Research Intern. Summer 2001. Developed a research prototype intrusion detection system. 
* *Microsoft*. Software Development Engineer in Test Intern. Summer 1999 and Summer 2000. Developed automated tests for Microsoft Commerce Server. Developed an automated stress testing system.

In The News
-----------

* On April 1, 2022, I was a guest on the nationally syndicated ratio show/podcast "Let's Go There w/ Shira & Ryan", where I talked about my Bitcoin research.
<!-- a listenership of more than 100k; broadcasts in over 35+ markets including Las Vegas, LA, New York, San Francisco, Chicago, Washington D.C., Dallas, Seattle, Philadelphia, Boston, New Orleans, and Miami.; https://www.audacy.com/podcasts/lets-go-there-with-shira-ryan-22293 -->
* On March 30, 2021, I was a guest speaker at the MSU IT Security forum: <https://web.microsoftstream.com/video/57daba68-5db7-4bb5-9cbc-434b410a8a7b>
* On March 14, 2021, I was a guest on Insider Threat: The #misec podcast: <https://podcast.insiderthreatpodcast.com/episode-14-if-you-give-a-man-a-phish>
* My paper about informal sources of security learning with Emilee Rader was highlighted on Bruce Schneier's blog: December 10, 2015: <https://www.schneier.com/blog/archives/2015/12/how_people_lear.html>
* I was interviewed about software updates and the Windows XP end-of-life on WILX TV: <http://www.wilx.com/topstories/headlines/Time-is-Running-Out-to-Upgrade-from-Windows-XP-254261871.html>
* My security stories paper with Emilee Rader and Brandon Brooks was written up by the TechRepublic: <http://www.techrepublic.com/blog/security/inside-your-users-brains-where-they-get-security-advice/8361>
* My collaborative NSF grant with Emilee Rader was picked up by the Associated Press, which caused it to get mentioned in a number of online sources:
    * Detroit Free Press: Jan 2, 2012. <http://www.freep.com/article/20120102/NEWS06/120102009/U-S-MSU-computer-security>
    * The Republic: Jan 2, 2012. <http://www.therepublic.com/view/story/fb75369eb3e24afe9a05d62728b1f0ed/MI--Home-Computer-Security/>
    * Lansing State Journal: Jan 2, 2012. <http://www.lansingstatejournal.com/usatoday/article/38251127>
    * Green Bay Press-Gazette (and many other Gannett papers): Jan 2, 2012. <http://www.greenbaypressgazette.com/usatoday/article/38251127>
    * WDIV Detroit: Jan 2, 2012. <http://www.clickondetroit.com/news/US-helps-MSU-profs-study-home-computer-security/-/1719418/7545626/-/90s71y/-/index.html>
    * Based on the MSU Press Release on Dec 16, 2011: http://news.msu.edu/story/10148
* I did a TV interview at 6 WILX TV in Lansing on Jan 24, 2012 about the Manti Te'o hoax and how people might protect themselves from similar deception.  <http://www.wlns.com/category/232735/video-landing-page?clipId=8236560&flvUri=&partnerclipid=&topVideoCatNo=106526&c=&autoStart=true&activePane=info&LaunchPageAdTag=homepage&clipFormat=flv>
* I did a live radio interview at WILS 1320 Talk Radio Lansing on Dec 16, 2011. <http://www.webwiseforradio.com/site_files/368/File/12-16-11_Rick%20Wash2%20.mp3>
* I did a recorded ratio interview on WQHH Power 96.5 fm in Lansing that aired on Sunday, March 11 2012 between 9:30am-10:00am about Google's new privacy policy changes
* My Folk Models of Security paper was highlighted by a number of computer industry venues:

   * Bruce Schneier: March 22, 2011. <http://www.schneier.com/blog/archives/2011/03/folk_models_in.html>
   * BoingBoing: March 22, 2011. <http://www.boingboing.net/2011/03/22/folk-models-of-home.html>
   * "Security Education: We're Doing It Wrong" SC Magazine.  by Lysa Myers. April 21, 2011. <http://www.scmagazineus.com/security-education-were-doing-it-wrong/article/201123/>
   * Michigan Public Radio: "Myths about online threats impact computer security" by Bridget Bodnar. May 25, 2011. <http://www.michiganradio.org/post/myths-about-online-threats-impact-computer-security>
   * ACM TechNews: "Home Computer Users at Risk Due to Use of 'Folk Model' Security". May 27, 2011. <http://technews.acm.org/archives.cfm?fo=2011-05-may/may-27-2011.html#523242>

* Wall Street Journal 1/15/04. Article about my anti-spam research. 
* Metromode "Defending the Net." by Tanya Muzumdar. 3/6/2008 Article about my security research -- <http://www.metromodemedia.com/features/TheNet0058.aspx>
* My security research was featured research in announcing the STIET (NSF IGERT) renewal grant. <http://www.umich.edu/~urecord/0708/Oct15_07/23.shtml> and <http://stiet.cms.si.umich.edu/sites/stiet.cms.si.umich.edu/files/DetroitFreePressonSTIET_Oct2007.pdf>
* STIET Newsletter Fall 2008 -- Article about my dissertation research and the the NSF grant that supports it. <http://stiet.cms.si.umich.edu/sites/stiet.cms.si.umich.edu/files/STIETNewsFall08.pdf>
