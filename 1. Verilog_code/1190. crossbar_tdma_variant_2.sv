//SystemVerilog
module crossbar_tdma #(DW=8, N=4) (
    input clk,
    input rst,
    input [31:0] global_time,
    input [N-1:0][DW-1:0] din,
    input valid_in,
    output valid_out,
    output reg [N-1:0][DW-1:0] dout
);
    // Extract time slot directly from inputs (moved register forward)
    wire [1:0] time_slot = global_time[27:26];
    wire [DW-1:0] selected_data = din[time_slot];
    wire route_valid = (time_slot < N) && valid_in;
    
    // Stage 1: Capture processed signals rather than raw inputs
    reg [1:0] time_slot_stage1;
    reg [DW-1:0] selected_data_stage1;
    reg valid_stage1;
    reg route_valid_stage1;
    
    // Stage 2: Preserved for pipeline balancing
    reg [1:0] time_slot_stage2;
    reg [DW-1:0] selected_data_stage2;
    reg valid_stage2;
    reg route_valid_stage2;
    
    // Pipeline Stage 1: Register the processed signals
    always @(posedge clk) begin
        if (rst) begin
            time_slot_stage1 <= 2'b0;
            selected_data_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
            route_valid_stage1 <= 1'b0;
        end
        else begin
            time_slot_stage1 <= time_slot;
            selected_data_stage1 <= selected_data;
            valid_stage1 <= valid_in;
            route_valid_stage1 <= route_valid;
        end
    end
    
    // Pipeline Stage 2: Maintain pipeline depth
    always @(posedge clk) begin
        if (rst) begin
            time_slot_stage2 <= 2'b0;
            selected_data_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
            route_valid_stage2 <= 1'b0;
        end
        else begin
            time_slot_stage2 <= time_slot_stage1;
            selected_data_stage2 <= selected_data_stage1;
            valid_stage2 <= valid_stage1;
            route_valid_stage2 <= route_valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Output routing
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                dout[i] <= {DW{1'b0}};
            end
        end
        else begin
            for (i = 0; i < N; i = i + 1) begin
                if (route_valid_stage2) begin
                    dout[i] <= selected_data_stage2;
                end
                else begin
                    dout[i] <= {DW{1'b0}};
                end
            end
        end
    end
    
    // Output valid signal
    assign valid_out = valid_stage2;
    
endmodule