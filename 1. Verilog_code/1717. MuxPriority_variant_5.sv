//SystemVerilog
module MuxPriority #(parameter W=8, N=4) (
    input [N-1:0] valid,
    input [W-1:0] data [0:N-1],
    output reg [W-1:0] result
);

    wire [N-1:0] priority_mask;
    wire [W-1:0] selected_data [0:N-1];
    
    // Generate priority mask using parallel prefix computation
    assign priority_mask[0] = valid[0];
    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin : gen_priority
            wire [i:0] valid_chain;
            assign valid_chain[0] = 1'b1;
            assign valid_chain[i:1] = ~valid[i-1:0];
            assign priority_mask[i] = valid[i] & &valid_chain;
        end
    endgenerate
    
    // Select data using parallel muxing
    genvar j;
    generate
        for (j = 0; j < N; j = j + 1) begin : gen_select
            assign selected_data[j] = {W{priority_mask[j]}} & data[j];
        end
    endgenerate
    
    // Combine results using parallel OR reduction
    always @(*) begin
        integer k;
        result = selected_data[0];
        k = 1;
        while (k < N) begin
            result = result | selected_data[k];
            k = k + 1;
        end
    end

endmodule