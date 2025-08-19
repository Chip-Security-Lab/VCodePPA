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
    
    // Format-specific conversion logic
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            case (format_select)
                2'b00: begin // RGB conversion
                    if (INBUS_WIDTH >= 24 && OUTBUS_WIDTH >= 16) begin
                        // RGB888 to RGB565
                        data_out[OUTBUS_WIDTH-1:OUTBUS_WIDTH-5] <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-5];
                        data_out[OUTBUS_WIDTH-6:OUTBUS_WIDTH-11] <= data_in[INBUS_WIDTH-9:INBUS_WIDTH-14];
                        data_out[OUTBUS_WIDTH-12:OUTBUS_WIDTH-16] <= data_in[INBUS_WIDTH-17:INBUS_WIDTH-21];
                        if (OUTBUS_WIDTH > 16)
                            data_out[OUTBUS_WIDTH-17:0] <= {(OUTBUS_WIDTH-16){1'b0}};
                    end else
                        data_out <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
                end
                2'b01: begin // YUV conversion (simplified)
                    data_out <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
                end
                2'b10: begin // MONO conversion - extract luminance
                    data_out <= {OUTBUS_WIDTH{data_in[INBUS_WIDTH-1]}};
                end
                2'b11: begin // RAW passthrough with truncation/padding
                    data_out <= data_in[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
                end
            endcase
        end
    end
endmodule