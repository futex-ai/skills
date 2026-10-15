# Retry protocol

The batch loader retries a rejected line at most twice, with the same
input. A third rejection stops the batch and reports the line number.
