//SystemVerilog
module Demux_FSM #(parameter DW=8) (
    input clk, rst,
    input [1:0] state,
    input [DW-1:0] data,
    output reg [3:0][DW-1:0] out
);
    parameter S0=0, S1=1, S2=2, S3=3;
    
    // Pipeline stage 1 registers
    reg [1:0] state_stage1;
    reg [DW-1:0] data_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] state_stage2;
    reg [DW-1:0] data_stage2;
    
    // Pre-decoded output enables (moved before final register)
    reg [3:0] out_enables;
    reg [DW-1:0] data_stage3;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= 2'b0;
            data_stage1 <= {DW{1'b0}};
        end else begin
            state_stage1 <= state;
            data_stage1 <= data;
        end
    end
    
    // Pipeline stage 2: Additional processing stage
    always @(posedge clk) begin
        if (rst) begin
            state_stage2 <= 2'b0;
            data_stage2 <= {DW{1'b0}};
        end else begin
            state_stage2 <= state_stage1;
            data_stage2 <= data_stage1;
        end
    end
    
    // Pipeline stage 3: Pre-decode output enables
    always @(posedge clk) begin
        if (rst) begin
            out_enables <= 4'b0;
            data_stage3 <= {DW{1'b0}};
        end else begin
            data_stage3 <= data_stage2;
            case (state_stage2)
                S0: out_enables <= 4'b0001;
                S1: out_enables <= 4'b0010;
                S2: out_enables <= 4'b0100;
                S3: out_enables <= 4'b1000;
                default: out_enables <= 4'b0000;
            endcase
        end
    end
    
    // Final stage: Register outputs with pre-decoded enables
    always @(posedge clk) begin
        if (rst) begin
            out <= {4{{{DW{1'b0}}}}};
        end else begin
            if (out_enables[0]) out[0] <= data_stage3;
            if (out_enables[1]) out[1] <= data_stage3;
            if (out_enables[2]) out[2] <= data_stage3;
            if (out_enables[3]) out[3] <= data_stage3;
        end
    end
endmodule