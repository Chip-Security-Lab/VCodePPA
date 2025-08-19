//SystemVerilog
// Top-level module: AXI4-Lite onehot_mux
module onehot_mux_axi4lite #(
    parameter ADDR_WIDTH = 4, // 4 bits to address 4 registers
    parameter DATA_WIDTH = 8
)(
    input  wire                  ACLK,
    input  wire                  ARESETN,

    // AXI4-Lite write address channel
    input  wire [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                  S_AXI_AWVALID,
    output reg                   S_AXI_AWREADY,

    // AXI4-Lite write data channel
    input  wire [DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                  S_AXI_WVALID,
    output reg                   S_AXI_WREADY,

    // AXI4-Lite write response channel
    output reg  [1:0]            S_AXI_BRESP,
    output reg                   S_AXI_BVALID,
    input  wire                  S_AXI_BREADY,

    // AXI4-Lite read address channel
    input  wire [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                  S_AXI_ARVALID,
    output reg                   S_AXI_ARREADY,

    // AXI4-Lite read data channel
    output reg  [DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg  [1:0]            S_AXI_RRESP,
    output reg                   S_AXI_RVALID,
    input  wire                  S_AXI_RREADY
);

    // Internal registers for memory-mapped registers
    reg [3:0]  one_hot_sel_reg;
    reg [7:0]  in0_reg, in1_reg, in2_reg, in3_reg;
    wire [7:0] data_out_wire;

    // AXI4-Lite internal write/read state
    reg write_addr_enable;

    // Address decoding
    localparam ADDR_SEL   = 4'h0;
    localparam ADDR_IN0   = 4'h4;
    localparam ADDR_IN1   = 4'h8;
    localparam ADDR_IN2   = 4'hC;
    localparam ADDR_IN3   = 4'h10;
    localparam ADDR_OUT   = 4'h14;

    // -- Intermediate signals for control flow decomposition --
    wire aw_ready_next;
    wire aw_handshake;
    wire b_handshake;
    wire w_ready_next;
    wire w_handshake;
    wire ar_ready_next;
    wire ar_handshake;
    wire r_handshake;
    wire write_enable;

    assign aw_handshake = (~S_AXI_AWREADY) && S_AXI_AWVALID && S_AXI_WVALID && write_addr_enable;
    assign b_handshake  = S_AXI_BVALID && S_AXI_BREADY;
    assign aw_ready_next = aw_handshake ? 1'b1 :
                           b_handshake  ? 1'b0 :
                           1'b0;

    assign w_handshake = (~S_AXI_WREADY) && S_AXI_WVALID && S_AXI_AWVALID && write_addr_enable;
    assign w_ready_next = w_handshake ? 1'b1 : 1'b0;

    assign ar_handshake = (~S_AXI_ARREADY) && S_AXI_ARVALID;
    assign ar_ready_next = ar_handshake ? 1'b1 : 1'b0;

    assign write_enable = S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID;

    // Write address handshake
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            write_addr_enable <= 1'b1;
        end else begin
            if (aw_handshake) begin
                S_AXI_AWREADY <= 1'b1;
                write_addr_enable <= 1'b0;
            end else if (b_handshake) begin
                S_AXI_AWREADY <= 1'b0;
                write_addr_enable <= 1'b1;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_WREADY <= 1'b0;
        end else begin
            if (w_handshake) begin
                S_AXI_WREADY <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            one_hot_sel_reg <= 4'b0001;
            in0_reg <= 8'd0;
            in1_reg <= 8'd0;
            in2_reg <= 8'd0;
            in3_reg <= 8'd0;
        end else if (write_enable) begin
            if (S_AXI_AWADDR == ADDR_SEL) begin
                one_hot_sel_reg <= S_AXI_WDATA[3:0];
            end else if (S_AXI_AWADDR == ADDR_IN0) begin
                in0_reg <= S_AXI_WDATA;
            end else if (S_AXI_AWADDR == ADDR_IN1) begin
                in1_reg <= S_AXI_WDATA;
            end else if (S_AXI_AWADDR == ADDR_IN2) begin
                in2_reg <= S_AXI_WDATA;
            end else if (S_AXI_AWADDR == ADDR_IN3) begin
                in3_reg <= S_AXI_WDATA;
            end
        end
    end

    // Write response
    wire write_resp_start;
    assign write_resp_start = S_AXI_AWREADY && S_AXI_AWVALID && ~S_AXI_BVALID && S_AXI_WREADY && S_AXI_WVALID;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP <= 2'b00;
        end else begin
            if (write_resp_start) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00; // OKAY
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
        end else begin
            if (ar_handshake) begin
                S_AXI_ARREADY <= 1'b1;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
        end
    end

    // Read data channel
    wire read_start;
    assign read_start = S_AXI_ARREADY && S_AXI_ARVALID && ~S_AXI_RVALID;
    wire read_done;
    assign read_done = S_AXI_RVALID && S_AXI_RREADY;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP  <= 2'b00;
            S_AXI_RDATA  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (read_start) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP  <= 2'b00; // OKAY
                if (S_AXI_ARADDR == ADDR_SEL) begin
                    S_AXI_RDATA <= {4'b0, one_hot_sel_reg};
                end else if (S_AXI_ARADDR == ADDR_IN0) begin
                    S_AXI_RDATA <= in0_reg;
                end else if (S_AXI_ARADDR == ADDR_IN1) begin
                    S_AXI_RDATA <= in1_reg;
                end else if (S_AXI_ARADDR == ADDR_IN2) begin
                    S_AXI_RDATA <= in2_reg;
                end else if (S_AXI_ARADDR == ADDR_IN3) begin
                    S_AXI_RDATA <= in3_reg;
                end else if (S_AXI_ARADDR == ADDR_OUT) begin
                    S_AXI_RDATA <= data_out_wire;
                end else begin
                    S_AXI_RDATA <= {DATA_WIDTH{1'b0}};
                end
            end else if (read_done) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

    // One-hot MUX logic (original functional core)
    wire [7:0] masked0, masked1, masked2, masked3;

    onehot_mask #(.WIDTH(8)) mask0 (
        .sel(one_hot_sel_reg[0]),
        .data_in(in0_reg),
        .data_masked(masked0)
    );

    onehot_mask #(.WIDTH(8)) mask1 (
        .sel(one_hot_sel_reg[1]),
        .data_in(in1_reg),
        .data_masked(masked1)
    );

    onehot_mask #(.WIDTH(8)) mask2 (
        .sel(one_hot_sel_reg[2]),
        .data_in(in2_reg),
        .data_masked(masked2)
    );

    onehot_mask #(.WIDTH(8)) mask3 (
        .sel(one_hot_sel_reg[3]),
        .data_in(in3_reg),
        .data_masked(masked3)
    );

    onehot_or #(.WIDTH(8), .NUM(4)) or_combiner (
        .data_in({masked3, masked2, masked1, masked0}),
        .data_out(data_out_wire)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: onehot_mask
// Description: Masks input data with the single-bit selection signal.
//              When sel=1, passes data_in; else outputs zero.
//-----------------------------------------------------------------------------
module onehot_mask #(
    parameter WIDTH = 8
)(
    input  wire        sel,
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_masked
);
    assign data_masked = {WIDTH{sel}} & data_in;
endmodule

//-----------------------------------------------------------------------------
// Submodule: onehot_or
// Description: OR-combines multiple masked data inputs.
//-----------------------------------------------------------------------------
module onehot_or #(
    parameter WIDTH = 8,
    parameter NUM = 4
)(
    input  wire [NUM*WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    genvar i;
    wire [WIDTH-1:0] data_array [0:NUM-1];

    generate
        for (i = 0; i < NUM; i = i + 1) begin : unpack
            assign data_array[i] = data_in[i*WIDTH +: WIDTH];
        end
    endgenerate

    assign data_out = data_array[0] | data_array[1] | data_array[2] | data_array[3];

endmodule