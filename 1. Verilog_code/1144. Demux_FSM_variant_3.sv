//SystemVerilog
module Demux_FSM #(parameter DW=8) (
    input clk, rst,
    input [1:0] state,
    input [DW-1:0] data,
    output reg [3:0][DW-1:0] out
);
    parameter S0=0, S1=1, S2=2, S3=3;
    
    // Register input data
    reg [DW-1:0] data_reg;
    
    // State register to capture state input
    reg [1:0] state_reg;
    
    // Clock data input registration
    always @(posedge clk) begin
        if(rst) begin
            data_reg <= 0;
        end
        else begin
            data_reg <= data;
        end
    end
    
    // Clock state input registration
    always @(posedge clk) begin
        if(rst) begin
            state_reg <= 0;
        end
        else begin
            state_reg <= state;
        end
    end
    
    // Output channel 0 control
    always @(posedge clk) begin
        if(rst) begin
            out[0] <= 0;
        end
        else if(state_reg == S0) begin
            out[0] <= data_reg;
        end
    end
    
    // Output channel 1 control
    always @(posedge clk) begin
        if(rst) begin
            out[1] <= 0;
        end
        else if(state_reg == S1) begin
            out[1] <= data_reg;
        end
    end
    
    // Output channel 2 control
    always @(posedge clk) begin
        if(rst) begin
            out[2] <= 0;
        end
        else if(state_reg == S2) begin
            out[2] <= data_reg;
        end
    end
    
    // Output channel 3 control
    always @(posedge clk) begin
        if(rst) begin
            out[3] <= 0;
        end
        else if(state_reg == S3) begin
            out[3] <= data_reg;
        end
    end
endmodule