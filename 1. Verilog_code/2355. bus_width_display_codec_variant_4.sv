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
    // Internal signals for data conversion
    reg [OUTBUS_WIDTH-1:0] converted_data;
    
    // 2-bit binary complementary subtractor implementation
    reg [1:0] subtractor_a, subtractor_b;
    reg [1:0] subtractor_result;
    reg subtractor_borrow;
    
    // Subtractor implementation using two's complement
    always @(*) begin
        subtractor_b = ~format_select + 2'b01; // Two's complement of format_select
        subtractor_a = 2'b11; // Maximum value for comparison
        {subtractor_borrow, subtractor_result} = {1'b0, subtractor_a} + {1'b0, subtractor_b};
    end
    
    // Format-specific conversion logic
    always @(*) begin
        case (subtractor_result)
            2'b00: begin // RGB conversion (format_select = 2'b11)
                if (INBUS_WIDTH >= 24 && OUTBUS_WIDTH >= 16) begin
                    // RGB888 to RGB565
                    converted_data[OUTBUS_WIDTH-1:OUTBUS_WIDTH-5] = data_in[INBUS_WIDTH-1:INBUS_WIDTH-5];
                    converted_data[OUTBUS_WIDTH-6:OUTBUS_WIDTH-11] = data_in[INBUS_WIDTH-9:INBUS_WIDTH-14];
                    converted_data[OUTBUS_WIDTH-12:OUTBUS_WIDTH-16] = data_in[INBUS_WIDTH-17:INBUS_WIDTH-21];
                    if (OUTBUS_WIDTH > 16)
                        converted_data[OUTBUS_WIDTH-17:0] = {(OUTBUS_WIDTH-16){1'b0}};
                end else
                    converted_data = data_in[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
            end
            2'b01: begin // YUV conversion (format_select = 2'b10)
                converted_data = data_in[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
            end
            2'b10: begin // MONO conversion (format_select = 2'b01)
                converted_data = {OUTBUS_WIDTH{data_in[INBUS_WIDTH-1]}};
            end
            2'b11: begin // RAW passthrough (format_select = 2'b00)
                converted_data = data_in[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
            end
            default: begin
                converted_data = {OUTBUS_WIDTH{1'b0}};
            end
        endcase
    end
    
    // Clock gating control signal (registered)
    reg clk_en_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_en_reg <= 1'b0;
        else
            clk_en_reg <= clk_en;
    end
    
    // Gated clock generation
    wire gated_clk;
    assign gated_clk = clk & clk_en_reg;
    
    // Output register
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            data_out <= converted_data;
        end
    end
endmodule