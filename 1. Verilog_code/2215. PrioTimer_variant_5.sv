//SystemVerilog
module PrioTimer #(parameter N=4) (
    input wire clk, rst_n,
    input wire [N-1:0] req,
    output reg [$clog2(N)-1:0] grant
);
    reg [7:0] cnt [0:N-1];
    reg [7:0] cnt_gt_threshold [0:N-1]; // Retimed comparison result
    reg [$clog2(N)-1:0] next_grant;     // Intermediate signal for grant calculation
    
    // Individual counter management for each request
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : cnt_block
            always @(posedge clk) begin
                if (!rst_n)
                    cnt[g] <= 8'h00;
                else if (req[g])
                    cnt[g] <= cnt[g] + 8'h01;
            end
        end
    endgenerate
    
    // Threshold comparison logic for each counter
    generate
        for (g = 0; g < N; g = g + 1) begin : threshold_block
            always @(posedge clk) begin
                if (!rst_n)
                    cnt_gt_threshold[g] <= 1'b0;
                else
                    cnt_gt_threshold[g] <= (cnt[g] > 8'h7F);
            end
        end
    endgenerate
    
    // Priority encoder logic
    integer i;
    always @(*) begin
        next_grant = {$clog2(N){1'b0}}; // Default value
        for (i = N-1; i >= 0; i = i - 1)
            if (cnt_gt_threshold[i]) 
                next_grant = i[$clog2(N)-1:0];
    end
    
    // Output register
    always @(posedge clk) begin
        if (!rst_n)
            grant <= {$clog2(N){1'b0}};
        else
            grant <= next_grant;
    end
endmodule