import Foundation

let mdQuery = NSMetadataQuery()
mdQuery.predicate = NSPredicate(format: "%K CONTAINS[cd] %@ AND (%K == 'public.data' OR %K == 'public.folder')", NSMetadataItemFSNameKey, "test", NSMetadataItemContentTypeTreeKey, NSMetadataItemContentTypeTreeKey)
print(mdQuery.predicate!)
