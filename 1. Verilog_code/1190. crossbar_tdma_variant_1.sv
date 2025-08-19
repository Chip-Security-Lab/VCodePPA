//SystemVerilog
module crossbar_tdma #(DW=8, N=4) (
    input clk, 
    input [31:0] global_time,
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    // Pipeline registers for time slot extraction
    reg [1:0] time_slot_r1;
    reg [1:0] time_slot_r2;
    reg [DW-1:0] selected_din_r;
    reg valid_slot_r1, valid_slot_r2;
    
    // First pipeline stage - extract time slot and check validity
    always @(posedge clk) begin
        time_slot_r1 <= global_time[27:26];
        valid_slot_r1 <= (global_time[27:26] < N);
    end
    
    // Second pipeline stage - select input data based on time slot
    always @(posedge clk) begin
        time_slot_r2 <= time_slot_r1;
        valid_slot_r2 <= valid_slot_r1;
        selected_din_r <= din[time_slot_r1];
    end
    
    // Final stage - route the selected data to all outputs
    integer i;
    always @(posedge clk) begin
        for (i = 0; i < N; i = i + 1) begin
            if (valid_slot_r2)
                dout[i] <= selected_din_r;
            else
                dout[i] <= {DW{1'b0}};
        end
    end
    
endmodule