# Solution to Reduce Dataverse Storage Cost by Offloading Recordings to Azure Blob Storage

Across the Dataverse Storage Assessments I have delivered so far, one universal challenge has been the same: storage keeps growing while the Power Platform and Dynamics admin teams are not always clear about what can be safely deleted, archived, or moved out of Dataverse to bring the File Capacity back under control.

This is even more common in Dynamics 365 Contact Center environments, where inbound and outbound call recordings need to be retained for quality and compliance purposes for several years. That can quickly balloon Dataverse storage, because recordings live under the File Capacity bucket.

Below is a practical approach that was implemented in a live customer environment and has worked well by reducing the storage footprint significantly.

## Let’s understand what Dataverse Storage actually is

Dataverse capacity is reported in three buckets: Data, File, and Log. Recordings sit in File.

Behind the scenes, Dataverse runs on Azure. Data lands in Azure SQL, File lands in Azure Storage, and Log lands in Azure Log Storage — all managed by Microsoft. So, call recordings are already sitting on Azure Blob Storage in the background. You just don’t see it that way because Microsoft presents it to you as Dataverse File capacity and prices it accordingly.

The key learning is simple: since the audio file is already going to end up on Azure Storage anyway, we can bypass the Dataverse File layer and put it into our own Azure Blob Storage account at a fraction of the cost.

## Choosing the target storage

The most practical solution is to offload recordings to a secure, enterprise-grade storage account that is cheaper than Dataverse, compliant, disaster-recovery capable, geo-redundant, and easy to integrate with Dataverse with minimal custom code. Azure Blob Storage meets all of those conditions, and most customers are already on Azure, which makes the integration straightforward and cost-effective.

## How the solution works

The offloading process is built with two Power Automate flows.

### Parent flow (scheduled)

1. Trigger — runs every day (or any other recurrence you choose)
2. Get conversations — lists conversations from `msdyn_ocliveworkitem` that are complete and older than 90 days. The age and status conditions are configurable.
3. Get related recordings — for each conversation, list the related rows from the Recordings table (`msdyn_ocrecording`). Not every conversation has a recording, so the flow checks the length of the returned collection and skips anything empty. This avoids unnecessary failures and saves API calls.
4. Get a download link (HTTP 1) — for each recording, call the Dataverse `GetFileSasUrl` function against the recording’s file column. This returns metadata and a short-lived SAS URL pointing to the file inside Dataverse. This SAS URL is valid for roughly an hour.
5. Download the audio (HTTP 2) — perform a second GET against that SAS URL to pull the audio bytes into the flow.
6. Create blob — use Create blob (V2), passing the body of HTTP 2 as the blob content, a `.mp3` blob name, and a folder path built by concatenating the year from the recording’s created-on date. This creates a year-wise folder structure such as 2023, 2024, 2025 automatically, with no manual folder management.
7. Create a playback link — use Create SAS URI by path against the newly written blob to generate a read-only link that the business can use. This SAS URI is issued by Azure Blob Storage and is valid for the next 5 years (or any validity period you define).
8. Write back to Dataverse — update the conversation record with that blob SAS URI.

### Child flow

Once the blob upload is confirmed, the child flow issues an HTTP DELETE against the file column on the recording record:

```http
DELETE /api/data/v9.2/msdyn_ocrecordings(<recordingid>)/msdyn_recording
```

This call targets only the File Column data of the Recording table and does not delete the entire record. The actual recording row remains in Dataverse with all of its business context intact — conversation reference, created-on, duration, state code, status code, and all other metadata. Only the stored audio or `.mp3` is removed.

This is an important design decision from a technical point of view. First, the audit and reporting trail remains intact, so anything built on the Recordings table continues working and remains auditable. Second, and more importantly, the audio file is what consumes File capacity. The remaining data in other columns consumes Data capacity, which is far smaller. This means storage reduction is achieved without losing the record that the call ever existed.

## Keeping the end-user experience intact

Since we are moving old recordings outside of Dataverse, there could be a business case where end users still need to access the file. It is highly unlikely that business users will browse Azure Blob Storage directly, and a raw SAS URL is not a good user experience because it opens a new tab and breaks the workflow. To avoid that, a PCF Gallery control was used on the Conversation form to play the audio directly from the blob link inside Dynamics 365 Contact Center, on the same form where standard Dataverse recordings are usually played.

The user stays on the same tab and clicks once — same experience as before. From the end-user’s standpoint, nothing has changed. That is a major confidence factor for the business.

## Result

For one customer, this solution delivered approximately a 60% reduction in Dataverse File capacity so far, which translated into about a 90% cost reduction in that storage because Dataverse File capacity is billed at roughly $2 per GB per month, while Azure Blob Storage is around $0.01 per GB per month.

The effort to build the offloading mechanism — writing the flows, testing them thoroughly, setting up the storage account, service principal, and client secret — is a one-time investment. The savings repeat every month for years.

- Hope it helps. You can reach out to me at bhavyadamani@hotmail.com in case you would need to talk in detail.
