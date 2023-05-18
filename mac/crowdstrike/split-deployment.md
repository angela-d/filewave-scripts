# Controlling Deployment by Hardware Type
This is the *only* way apps that have extension requirements should be deployed.

Once this has been created, it's a one and done setup; the smart groups go out and automatically apply themselves to any matching machines.
**DO NOT deploy Crowd Strike to any machine via manual association.**

1. Select **Clients** from the left menu, in Filewave Admin
2. Select **Groups** from the top menu
3. Search: `smart groups`
    - Click the Name column to sort alphabetically
    - Locate **Smart Groups**
    - Right-click > Reveal in Tree
    - Expand the > carat and locate the smart groups:
        - Crowd Strike Intel Assignment - Phase 1
        - Crowd Strike Intel PKG Deployment - Phase 2
        - Crowd Strike Intel Script Deployment - Phase 3
    - Associate the **Intel** profile (Profile - Crowd Strike Falcon Profile - Intel) to *Crowd Strike Intel Assignment - Phase 1*
    - Associate **Profile - Crowd Strike Login Item** to *Crowd Strike Intel Assignment - Phase 1*
    - Associate **Profile - Disable Background Task Management Notifications** to *Crowd Strike Intel Assignment - Phase 1*
    - Associate **the group `Crowd Strike PKG`** to *Crowd Strike Intel PKG Deployment - Phase 2* -- DO NOT deploy the PKG directly!
    - Associate ** Crowdstrike License** to **Crowd Strike Intel Script Deployment - Phase 3**
4. Update model; Filewave will not auto associate the Crowd Strike components to any machine matching the Smart Group queries.

Repeat for M1, but replace **Intel** for **M1** in the Smart Groups + profiles.
