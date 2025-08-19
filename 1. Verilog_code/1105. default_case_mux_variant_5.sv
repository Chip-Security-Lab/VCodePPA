//SystemVerilog
module valid_ready_mux #(
    parameter DATA_WIDTH = 16,
    parameter CHANNELS = 5
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [2:0]               channel_sel,
    input  wire [DATA_WIDTH-1:0]    ch0_data,
    input  wire                     ch0_valid,
    output wire                     ch0_ready,
    input  wire [DATA_WIDTH-1:0]    ch1_data,
    input  wire                     ch1_valid,
    output wire                     ch1_ready,
    input  wire [DATA_WIDTH-1:0]    ch2_data,
    input  wire                     ch2_valid,
    output wire                     ch2_ready,
    input  wire [DATA_WIDTH-1:0]    ch3_data,
    input  wire                     ch3_valid,
    output wire                     ch3_ready,
    input  wire [DATA_WIDTH-1:0]    ch4_data,
    input  wire                     ch4_valid,
    output wire                     ch4_ready,
    output reg  [DATA_WIDTH-1:0]    mux_out_data,
    output reg                      mux_out_valid,
    input  wire                     mux_out_ready
);

    // Efficient channel selection using range check and one-hot encoding
    wire [CHANNELS-1:0] channel_onehot;
    assign channel_onehot = (channel_sel < CHANNELS) ? (1'b1 << channel_sel) : {CHANNELS{1'b0}};

    // Data/valid mux using case statement for efficient implementation
    reg [DATA_WIDTH-1:0] selected_data;
    reg                  selected_valid;

    always @(*) begin
        case (channel_sel)
            3'b000: begin
                selected_data  = ch0_data;
                selected_valid = ch0_valid;
            end
            3'b001: begin
                selected_data  = ch1_data;
                selected_valid = ch1_valid;
            end
            3'b010: begin
                selected_data  = ch2_data;
                selected_valid = ch2_valid;
            end
            3'b011: begin
                selected_data  = ch3_data;
                selected_valid = ch3_valid;
            end
            3'b100: begin
                selected_data  = ch4_data;
                selected_valid = ch4_valid;
            end
            default: begin
                selected_data  = {DATA_WIDTH{1'b0}};
                selected_valid = 1'b0;
            end
        endcase
    end

    wire selected_ready = mux_out_ready;

    // Ready signal generation for each channel (optimized one-hot)
    assign ch0_ready = channel_onehot[0] & selected_ready;
    assign ch1_ready = channel_onehot[1] & selected_ready;
    assign ch2_ready = channel_onehot[2] & selected_ready;
    assign ch3_ready = channel_onehot[3] & selected_ready;
    assign ch4_ready = channel_onehot[4] & selected_ready;

    // Output valid/data generation with pipelining for improved timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_data  <= {DATA_WIDTH{1'b0}};
            mux_out_valid <= 1'b0;
        end else begin
            if (selected_valid && selected_ready) begin
                mux_out_data  <= selected_data;
                mux_out_valid <= 1'b1;
            end else if (mux_out_ready) begin
                mux_out_valid <= 1'b0;
            end
        end
    end

endmodule