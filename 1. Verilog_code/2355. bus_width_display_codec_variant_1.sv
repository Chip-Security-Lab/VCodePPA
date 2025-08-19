//SystemVerilog
module bus_width_display_codec #(
    parameter INBUS_WIDTH = 32,
    parameter OUTBUS_WIDTH = 16
) (
    input clk, rst_n,
    input clk_en,  // Clock gating control
    input [INBUS_WIDTH-1:0] data_in,
    input [1:0] format_select,  // 0: RGB, 1: YUV, 2: MONO, 3: RAW
    output reg [OUTBUS_WIDTH-1:0] data_out
);
    // Internal gated clock
    wire gated_clk;
    assign gated_clk = clk & clk_en;
    
    // Subtractor using LUT-assisted algorithm
    reg [1:0] sub_a, sub_b;
    wire [1:0] sub_result;
    reg [3:0] sub_lut_addr;
    reg [1:0] sub_lut_output;
    
    // LUT for 2-bit subtraction - optimized implementation
    always @(*) begin
        sub_lut_addr = {sub_a, sub_b};
        
        // Initial value assignment
        sub_lut_output = 2'b00;
        
        // While loop implementation instead of case statement
        begin
            integer i;
            i = 0;
            while (i < 16) begin
                if (sub_lut_addr == i) begin
                    case (i)
                        4'b0000: sub_lut_output = 2'b00; // 0 - 0 = 0
                        4'b0001: sub_lut_output = 2'b11; // 0 - 1 = -1 (3 in 2-bit)
                        4'b0010: sub_lut_output = 2'b10; // 0 - 2 = -2 (2 in 2-bit)
                        4'b0011: sub_lut_output = 2'b01; // 0 - 3 = -3 (1 in 2-bit)
                        4'b0100: sub_lut_output = 2'b01; // 1 - 0 = 1
                        4'b0101: sub_lut_output = 2'b00; // 1 - 1 = 0
                        4'b0110: sub_lut_output = 2'b11; // 1 - 2 = -1 (3 in 2-bit)
                        4'b0111: sub_lut_output = 2'b10; // 1 - 3 = -2 (2 in 2-bit)
                        4'b1000: sub_lut_output = 2'b10; // 2 - 0 = 2
                        4'b1001: sub_lut_output = 2'b01; // 2 - 1 = 1
                        4'b1010: sub_lut_output = 2'b00; // 2 - 2 = 0
                        4'b1011: sub_lut_output = 2'b11; // 2 - 3 = -1 (3 in 2-bit)
                        4'b1100: sub_lut_output = 2'b11; // 3 - 0 = 3
                        4'b1101: sub_lut_output = 2'b10; // 3 - 1 = 2
                        4'b1110: sub_lut_output = 2'b01; // 3 - 2 = 1
                        4'b1111: sub_lut_output = 2'b00; // 3 - 3 = 0
                    endcase
                end
                i = i + 1;
            end
        end
    end
    
    assign sub_result = sub_lut_output;
    
    // Format-specific conversion logic with LUT-assisted subtraction
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUTBUS_WIDTH{1'b0}};
            sub_a <= 2'b00;
            sub_b <= 2'b00;
        end else begin
            case (format_select)
                2'b00: begin // RGB conversion
                    if (INBUS_WIDTH >= 24 && OUTBUS_WIDTH >= 16) begin
                        // RGB888 to RGB565 using LUT-assisted subtraction
                        sub_a <= data_in[INBUS_WIDTH-3:INBUS_WIDTH-4]; // Extract 2 bits from R
                        sub_b <= 2'b01; // Fixed offset
                        
                        data_out[OUTBUS_WIDTH-1:OUTBUS_WIDTH-5] <= {data_in[INBUS_WIDTH-1:INBUS_WIDTH-3], sub_result};
                        data_out[OUTBUS_WIDTH-6:OUTBUS_WIDTH-11] <= data_in[INBUS_WIDTH-9:INBUS_WIDTH-14];
                        data_out[OUTBUS_WIDTH-12:OUTBUS_WIDTH-16] <= data_in[INBUS_WIDTH-17:INBUS_WIDTH-21];
                        if (OUTBUS_WIDTH > 16)
                            data_out[OUTBUS_WIDTH-17:0] <= {(OUTBUS_WIDTH-16){1'b0}};
                    end else begin
                        sub_a <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-2];
                        sub_b <= data_in[INBUS_WIDTH-3:INBUS_WIDTH-4];
                        data_out[OUTBUS_WIDTH-1:OUTBUS_WIDTH-2] <= sub_result;
                        data_out[OUTBUS_WIDTH-3:0] <= data_in[INBUS_WIDTH-5:INBUS_WIDTH-OUTBUS_WIDTH-2];
                    end
                end
                2'b01: begin // YUV conversion (simplified)
                    // Use LUT subtractor for Y component adjustment
                    sub_a <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-2];
                    sub_b <= 2'b10; // Apply offset for YUV conversion
                    data_out[OUTBUS_WIDTH-1:OUTBUS_WIDTH-2] <= sub_result;
                    data_out[OUTBUS_WIDTH-3:0] <= data_in[INBUS_WIDTH-3:INBUS_WIDTH-OUTBUS_WIDTH];
                end
                2'b10: begin // MONO conversion - extract luminance
                    sub_a <= {1'b0, data_in[INBUS_WIDTH-1]};
                    sub_b <= {1'b0, ~data_in[INBUS_WIDTH-1]};
                    data_out <= {OUTBUS_WIDTH{sub_result[0]}};
                end
                2'b11: begin // RAW passthrough with truncation/padding
                    sub_a <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-2];
                    sub_b <= 2'b00; // No offset for RAW
                    data_out[OUTBUS_WIDTH-1:OUTBUS_WIDTH-2] <= sub_result;
                    data_out[OUTBUS_WIDTH-3:0] <= data_in[INBUS_WIDTH-3:INBUS_WIDTH-OUTBUS_WIDTH];
                end
            endcase
        end
    end
endmodule