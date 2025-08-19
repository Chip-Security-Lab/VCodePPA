//SystemVerilog
module ArrayOR_AXIS (
    input wire aclk,
    input wire aresetn,

    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,

    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);

    // Internal signals for AXI-Stream handshake
    wire input_data_ready;
    wire input_data_valid;

    // Pipeline stage 1: Input handshake and data capture
    reg [7:0] pipeline1_data_reg;
    reg pipeline1_valid_reg;

    // Pipeline stage 2: Data processing
    reg [7:0] pipeline2_data_reg;
    reg pipeline2_valid_reg;

    // Stage 1 handshake: Ready to accept new data if pipeline 1 is not full
    assign s_axis_tready = ~pipeline1_valid_reg;

    // Stage 1 valid: Data is valid from input and accepted
    assign input_data_valid = s_axis_tvalid & s_axis_tready;

    // Stage 1 processing: Capture data and valid flag
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            pipeline1_data_reg <= 8'h00;
            pipeline1_valid_reg <= 1'b0;
        end else begin
            case ({input_data_valid, pipeline1_valid_reg, pipeline2_valid_reg})
                3'b100, 3'b101, 3'b110, 3'b111 : begin // input_data_valid is high
                    pipeline1_data_reg <= s_axis_tdata;
                    pipeline1_valid_reg <= 1'b1;
                end
                3'b010 : begin // pipeline1_valid_reg is high and pipeline2_valid_reg is low
                    // Pass data to next stage if next stage is ready
                    pipeline1_valid_reg <= 1'b0; // Clear valid after passing
                end
                default : begin
                    // No change or other cases handled implicitly
                end
            endcase
        end
    end

    // Stage 2 handshake: Ready to accept data from stage 1 if pipeline 2 is not full
    wire pipeline2_ready = ~pipeline2_valid_reg;
    wire pipeline1_to_pipeline2_transfer = pipeline1_valid_reg & pipeline2_ready;

    // Stage 2 processing: Perform OR operation
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            pipeline2_data_reg <= 8'h00;
            pipeline2_valid_reg <= 1'b0;
        end else begin
             case ({pipeline1_to_pipeline2_transfer, pipeline2_valid_reg, m_axis_tready})
                3'b100, 3'b101, 3'b110, 3'b111 : begin // pipeline1_to_pipeline2_transfer is high
                    pipeline2_data_reg <= pipeline1_data_reg | 8'hAA;
                    pipeline2_valid_reg <= 1'b1;
                end
                3'b011 : begin // pipeline2_valid_reg is high and m_axis_tready is high
                    // Pass data to output if output is ready
                    pipeline2_valid_reg <= 1'b0; // Clear valid after passing
                end
                default : begin
                    // No change or other cases handled implicitly
                end
            endcase
        end
    end

    // Output AXI-Stream handshake
    assign m_axis_tdata = pipeline2_data_reg;
    assign m_axis_tvalid = pipeline2_valid_reg;

endmodule