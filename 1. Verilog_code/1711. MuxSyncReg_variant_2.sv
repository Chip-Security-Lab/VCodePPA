//SystemVerilog
module MuxSyncReg #(parameter W=8, N=4) (
    input clk, rst_n,
    input [N-1:0][W-1:0] data_in,
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] data_out
);

    // Stage 1: Decode and Mux
    reg [N-1:0] sel_decoded_stage1;
    reg [W-1:0] mux_data_stage1;
    
    // Stage 2: Register output
    reg [W-1:0] data_out_stage2;
    
    // Stage 1 logic
    always @(*) begin
        sel_decoded_stage1 = (1'b1 << sel);
        
        // Generate multiplexed data
        mux_data_stage1 = {W{1'b0}};
        for (int i = 0; i < N; i = i + 1) begin
            if (sel_decoded_stage1[i]) begin
                mux_data_stage1 = data_in[i];
            end
        end
    end
    
    // Stage 2 register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage2 <= {W{1'b0}};
        end else begin
            data_out_stage2 <= mux_data_stage1;
        end
    end
    
    // Output assignment
    assign data_out = data_out_stage2;

endmodule