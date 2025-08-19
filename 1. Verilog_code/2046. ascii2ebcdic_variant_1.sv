//SystemVerilog
module ascii2ebcdic (
    input wire clk,
    input wire enable,
    input wire [7:0] ascii_in,
    output reg [7:0] ebcdic_out,
    output reg valid_out
);

// Stage 1: Input register and enable latch
reg [7:0] ascii_in_stage1;
reg       enable_stage1;

// Input capturing
// Captures ascii_in and enable on the rising edge of clk
always @(posedge clk) begin : input_capture
    ascii_in_stage1 <= ascii_in;
    enable_stage1   <= enable;
end

// Stage 2: Partial decode registers
reg [1:0] code_type_stage2;
reg       enable_stage2;
reg [7:0] ascii_in_stage2;

// Pipeline ascii_in_stage1 and enable_stage1 to stage 2
// Handles pipeline register transfer
always @(posedge clk) begin : pipeline_stage2
    ascii_in_stage2  <= ascii_in_stage1;
    enable_stage2    <= enable_stage1;
end

// Partial decode logic for code_type_stage2
// Determines the type of input ascii code
always @(posedge clk) begin : code_type_decode
    case (ascii_in_stage1)
        8'h30, 8'h31: code_type_stage2 <= 2'b01; // digits 0,1
        8'h41, 8'h42: code_type_stage2 <= 2'b10; // A,B
        default:      code_type_stage2 <= 2'b00;
    endcase
end

// Stage 3: Output mapping and valid signal
reg [7:0] ebcdic_out_stage3;
reg       valid_stage3;

// Output mapping based on code_type_stage2 and ascii_in_stage2
// Handles EBCDIC mapping and sets valid signal
always @(posedge clk) begin : output_mapping
    ebcdic_out_stage3 <= 8'h00;
    valid_stage3      <= 1'b0;
    if (enable_stage2) begin
        case (code_type_stage2)
            2'b01: begin // Digit
                if (ascii_in_stage2 == 8'h30)
                    ebcdic_out_stage3 <= 8'hF0;
                else // 8'h31
                    ebcdic_out_stage3 <= 8'hF1;
                valid_stage3 <= 1'b1;
            end
            2'b10: begin // Uppercase alpha
                if (ascii_in_stage2 == 8'h41)
                    ebcdic_out_stage3 <= 8'hC1;
                else // 8'h42
                    ebcdic_out_stage3 <= 8'hC2;
                valid_stage3 <= 1'b1;
            end
            default: begin
                ebcdic_out_stage3 <= 8'h00;
                valid_stage3      <= 1'b0;
            end
        endcase
    end
end

// Stage 4: Output register
// Registers final outputs
always @(posedge clk) begin : output_register
    ebcdic_out <= ebcdic_out_stage3;
    valid_out  <= valid_stage3;
end

endmodule