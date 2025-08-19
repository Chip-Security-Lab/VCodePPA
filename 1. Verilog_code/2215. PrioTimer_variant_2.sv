//SystemVerilog
module PrioTimer #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [$clog2(N)-1:0] grant
);
    reg [7:0] cnt [0:N-1];
    // Buffer registers for high fanout signals, split to balance load
    reg [7:0] cnt_buf1_low [0:N/2-1];
    reg [7:0] cnt_buf1_high [0:N/2-1];
    reg [7:0] cnt_buf2_low [0:N/2-1];
    reg [7:0] cnt_buf2_high [0:N/2-1];
    // Final comparison result buffer
    reg [N-1:0] cmp_result;
    integer i;
    
    // First stage: Update counters
    always @(posedge clk) begin
        if (!rst_n) begin
            for(i=0; i<N; i=i+1)
                cnt[i] <= 8'h00;
        end
        else begin
            for(i=0; i<N; i=i+1)
                if(req[i])
                    cnt[i] <= cnt[i] + 8'h01;
        end
    end
    
    // Second stage: Buffer the counter values with load balancing
    always @(posedge clk) begin
        for(i=0; i<N/2; i=i+1) begin
            cnt_buf1_low[i] <= cnt[i];
            cnt_buf1_high[i] <= cnt[i+N/2];
        end
    end
    
    // Third stage: Additional buffer for priority logic
    always @(posedge clk) begin
        for(i=0; i<N/2; i=i+1) begin
            cnt_buf2_low[i] <= cnt_buf1_low[i];
            cnt_buf2_high[i] <= cnt_buf1_high[i];
        end
    end
    
    // Fourth stage: Comparison results buffering
    always @(posedge clk) begin
        for(i=0; i<N/2; i=i+1) begin
            cmp_result[i] <= (cnt_buf2_low[i] > 8'h7F);
            cmp_result[i+N/2] <= (cnt_buf2_high[i] > 8'h7F);
        end
    end
    
    // Final stage: Grant generation with buffered comparison results
    always @(posedge clk) begin
        grant <= {$clog2(N){1'b0}}; // Default value
        for(i=N-1; i>=0; i=i-1)
            if(cmp_result[i]) grant <= i[$clog2(N)-1:0];
    end
endmodule