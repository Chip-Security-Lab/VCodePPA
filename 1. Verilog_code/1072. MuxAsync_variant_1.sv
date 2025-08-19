//SystemVerilog
// Top-level module: Structured pipelined multiplexer with asynchronous data selection

module MuxAsync #(parameter DW=8, AW=3) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [AW-1:0]         channel,
    input  wire [2**AW-1:0][DW-1:0] din,
    output wire [DW-1:0]         dout
);

    // Pipeline Stage 1: Register channel input
    reg  [AW-1:0]                channel_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            channel_stage1 <= {AW{1'b0}};
        else
            channel_stage1 <= channel;
    end

    // Pipeline Stage 2: Channel Decoder (register output)
    wire [2**AW-1:0]             channel_onehot_stage2;
    ChannelDecoder #(
        .AW(AW)
    ) u_channel_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .channel_sel(channel_stage1),
        .onehot_out(channel_onehot_stage2)
    );

    // Pipeline Stage 3: Register data input
    reg [2**AW-1:0][DW-1:0]      din_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            din_stage3 <= {2**AW{{DW{1'b0}}}};
        else
            din_stage3 <= din;
    end

    // Pipeline Stage 4: Data Selector (register output)
    wire [DW-1:0]                data_selected_stage4;
    DataSelector #(
        .DW(DW),
        .AW(AW)
    ) u_data_selector (
        .clk(clk),
        .rst_n(rst_n),
        .din(din_stage3),
        .sel_onehot(channel_onehot_stage2),
        .dout(data_selected_stage4)
    );

    // Pipeline Stage 5: Register output
    reg [DW-1:0]                 dout_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout_stage5 <= {DW{1'b0}};
        else
            dout_stage5 <= data_selected_stage4;
    end

    assign dout = dout_stage5;

endmodule

// -----------------------------------------------------------------------------
// ChannelDecoder
// Converts a binary channel select value to a one-hot encoded output
// Registered output for pipelining
// -----------------------------------------------------------------------------
module ChannelDecoder #(parameter AW=3) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [AW-1:0]         channel_sel,
    output reg  [2**AW-1:0]      onehot_out
);
    integer i;
    reg [2**AW-1:0]              onehot_out_comb;

    always @(*) begin
        onehot_out_comb = {2**AW{1'b0}};
        for (i = 0; i < 2**AW; i = i + 1) begin
            if (channel_sel == i)
                onehot_out_comb[i] = 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_out <= {2**AW{1'b0}};
        else
            onehot_out <= onehot_out_comb;
    end
endmodule

// -----------------------------------------------------------------------------
// DataSelector
// Selects one data word from an array of inputs using a one-hot select signal
// Registered output for pipelining
// -----------------------------------------------------------------------------
module DataSelector #(parameter DW=8, AW=3) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [2**AW-1:0][DW-1:0] din,
    input  wire [2**AW-1:0]      sel_onehot,
    output reg  [DW-1:0]         dout
);
    integer j;
    reg [DW-1:0]                 dout_comb;

    always @(*) begin
        dout_comb = {DW{1'b0}};
        for (j = 0; j < 2**AW; j = j + 1) begin
            if (sel_onehot[j])
                dout_comb = din[j];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {DW{1'b0}};
        else
            dout <= dout_comb;
    end
endmodule