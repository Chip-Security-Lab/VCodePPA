//SystemVerilog
module async_rst_rotator (
    input clk, arst, en,
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out,
    output reg valid_out
);
    // Stage 1 registers
    reg [7:0] data_stage1;
    reg [2:0] shift_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [7:0] left_shifted_stage2;
    reg [7:0] right_shifted_stage2;
    reg valid_stage2;
    
    // Stage 1: Register data input
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            data_stage1 <= 8'b0;
        end else begin
            data_stage1 <= data_in;
        end
    end
    
    // Stage 1: Register shift input
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            shift_stage1 <= 3'b0;
        end else begin
            shift_stage1 <= shift;
        end
    end
    
    // Stage 1: Register enable signal
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= en;
        end
    end
    
    // Stage 2: Perform left shift
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            left_shifted_stage2 <= 8'b0;
        end else begin
            left_shifted_stage2 <= data_stage1 << shift_stage1;
        end
    end
    
    // Stage 2: Perform right shift
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            right_shifted_stage2 <= 8'b0;
        end else begin
            right_shifted_stage2 <= data_stage1 >> (8 - shift_stage1);
        end
    end
    
    // Stage 2: Propagate valid signal
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Generate output data
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            data_out <= 8'b0;
        end else begin
            data_out <= left_shifted_stage2 | right_shifted_stage2;
        end
    end
    
    // Stage 3: Generate output valid signal
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
        end
    end
endmodule