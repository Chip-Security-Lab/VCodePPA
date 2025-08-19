//SystemVerilog
module rng_cnt_xor_11_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                  clk,
    input                  rst,

    // AXI4-Lite Write Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                       s_axi_awvalid,
    output reg                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input      [7:0]            s_axi_wdata,
    input      [0:0]            s_axi_wstrb,
    input                       s_axi_wvalid,
    output reg                  s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]            s_axi_bresp,
    output reg                  s_axi_bvalid,
    input                       s_axi_bready,

    // AXI4-Lite Read Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_araddr,
    input                       s_axi_arvalid,
    output reg                  s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [7:0]            s_axi_rdata,
    output reg [1:0]            s_axi_rresp,
    output reg                  s_axi_rvalid,
    input                       s_axi_rready
);

    // Internal registers
    reg [7:0] counter;
    wire [7:0] next_counter;
    reg        en_reg;

    // Carry Lookahead Logic
    wire [7:0] carry_generate;
    wire [7:0] carry_propagate;
    wire [8:0] carry;

    assign carry_generate = counter & 8'b00000001;
    assign carry_propagate = counter ^ 8'b00000001;
    assign carry[0] = 1'b1;

    assign carry[1] = carry_generate[0] | (carry_propagate[0] & carry[0]);
    assign carry[2] = carry_generate[1] | (carry_propagate[1] & carry[1]);
    assign carry[3] = carry_generate[2] | (carry_propagate[2] & carry[2]);
    assign carry[4] = carry_generate[3] | (carry_propagate[3] & carry[3]);
    assign carry[5] = carry_generate[4] | (carry_propagate[4] & carry[4]);
    assign carry[6] = carry_generate[5] | (carry_propagate[5] & carry[5]);
    assign carry[7] = carry_generate[6] | (carry_propagate[6] & carry[6]);
    assign carry[8] = carry_generate[7] | (carry_propagate[7] & carry[7]);

    assign next_counter[0] = counter[0] ^ 1'b1;
    assign next_counter[1] = counter[1] ^ carry[1];
    assign next_counter[2] = counter[2] ^ carry[2];
    assign next_counter[3] = counter[3] ^ carry[3];
    assign next_counter[4] = counter[4] ^ carry[4];
    assign next_counter[5] = counter[5] ^ carry[5];
    assign next_counter[6] = counter[6] ^ carry[6];
    assign next_counter[7] = counter[7] ^ carry[7];

    // AXI4-Lite Registers
    localparam ADDR_COUNTER    = 4'h0;
    localparam ADDR_RND        = 4'h4;
    localparam ADDR_EN         = 4'h8;

    // AXI4-Lite Write FSM
    reg aw_en;

    // Read data mux
    wire [7:0] rnd_val;
    assign rnd_val = counter ^ {counter[3:0], counter[7:4]};

    // Combined always block for all sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // AXI4-Lite Write FSM
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
            // AXI4-Lite Read FSM
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            // Internal registers
            counter       <= 8'd0;
            en_reg        <= 1'b0;
        end else begin
            // -------------------- AXI4-Lite Write FSM --------------------
            // Write Address Ready
            if (~s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Write Data Ready
            if (~s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Write Response
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                aw_en        <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_en        <= 1'b1;
            end

            // -------------------- AXI4-Lite Read FSM ---------------------
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

            // -------------------- Internal Registers Write Logic ----------
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr)
                    ADDR_COUNTER: if (s_axi_wstrb[0]) counter <= s_axi_wdata;
                    ADDR_EN:      if (s_axi_wstrb[0]) en_reg  <= s_axi_wdata[0];
                    default: ;
                endcase
            end else if (en_reg) begin
                counter <= next_counter;
            end
        end
    end

    // Read data mux (combinational)
    always @(*) begin
        case (s_axi_araddr)
            ADDR_COUNTER: s_axi_rdata = counter;
            ADDR_RND:     s_axi_rdata = rnd_val;
            ADDR_EN:      s_axi_rdata = {7'd0, en_reg};
            default:      s_axi_rdata = 8'd0;
        endcase
    end

endmodule