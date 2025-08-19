//SystemVerilog
module sync_4input_mux_valid_ready #(
    parameter DATA_WIDTH = 1
)(
    input  wire                  clk,                  // Clock input
    input  wire                  rst_n,                // Active low reset
    input  wire [3:0]            data_inputs,          // 4 single-bit inputs
    input  wire [1:0]            addr,                 // Address selection
    input  wire                  in_valid,             // Input valid signal
    output wire                  in_ready,             // Input ready signal
    output reg  [DATA_WIDTH-1:0] mux_output,           // Registered output
    output reg                   out_valid,            // Output valid signal
    input  wire                  out_ready             // Output ready signal
);

    // Stage 1: Decode input and address selection, register pre-mux data
    reg                         stage1_valid;
    reg [DATA_WIDTH-1:0]        stage1_data;
    reg [1:0]                   stage1_addr;

    // Stage 2: Mux and register output
    reg                         stage2_valid;
    reg [DATA_WIDTH-1:0]        stage2_data;

    // Input ready: asserted when stage1 pipeline is ready to accept new data
    assign in_ready = ~stage1_valid | (stage2_valid & out_ready);

    // Stage 1: Latch input when in_valid and in_ready
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage1_data  <= {DATA_WIDTH{1'b0}};
            stage1_addr  <= 2'b00;
        end else if (in_valid && in_ready) begin
            stage1_valid <= 1'b1;
            stage1_data  <= data_inputs;
            stage1_addr  <= addr;
        end else if (stage2_valid && out_ready) begin
            stage1_valid <= 1'b0;
        end
    end

    // Stage 2: Mux selection and output valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
            stage2_data  <= {DATA_WIDTH{1'b0}};
        end else if (stage1_valid) begin
            stage2_valid <= 1'b1;
            case (stage1_addr)
                2'b00: stage2_data <= stage1_data[0];
                2'b01: stage2_data <= stage1_data[1];
                2'b10: stage2_data <= stage1_data[2];
                2'b11: stage2_data <= stage1_data[3];
                default: stage2_data <= {DATA_WIDTH{1'b0}};
            endcase
        end else if (stage2_valid && out_ready) begin
            stage2_valid <= 1'b0;
        end
    end

    // Output register: final output stage, drives mux_output and out_valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_output <= {DATA_WIDTH{1'b0}};
            out_valid  <= 1'b0;
        end else if (stage2_valid) begin
            mux_output <= stage2_data;
            out_valid  <= 1'b1;
        end else if (out_valid && out_ready) begin
            out_valid  <= 1'b0;
        end
    end

endmodule