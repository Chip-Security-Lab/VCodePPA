//SystemVerilog
module rng_async_mix_7_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   s_axi_aclk,
    input                   s_axi_aresetn,
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

    // Internal registers for memory-mapped in_cnt and out_rand
    reg [7:0] in_cnt_reg;
    wire [7:0] out_rand_wire;

    // Address Map
    localparam ADDR_IN_CNT  = 4'h0;
    localparam ADDR_OUT_RAND = 4'h4;

    // Write FSM
    reg aw_en;

    // Write Address handshake
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en <= 1'b1;
                s_axi_awready <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // Write Data handshake
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (!s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            in_cnt_reg <= 8'b0;
        end else if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
            if (s_axi_awaddr[ADDR_WIDTH-1:0] == ADDR_IN_CNT) begin
                if (s_axi_wstrb[0]) begin
                    in_cnt_reg <= s_axi_wdata;
                end
            end
        end
    end

    // Write Response logic
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read Address handshake
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // Read Data logic
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 8'b0;
        end else begin
            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                case (s_axi_araddr[ADDR_WIDTH-1:0])
                    ADDR_IN_CNT:   s_axi_rdata <= in_cnt_reg;
                    ADDR_OUT_RAND: s_axi_rdata <= out_rand_wire;
                    default:       s_axi_rdata <= 8'b0;
                endcase
                s_axi_rresp  <= 2'b00;
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Combinational logic for out_rand using conditional inversion subtractor algorithm
    wire [3:0] lower_xor;
    wire [3:0] upper_xor;
    wire [1:0] lower_add;
    wire [1:0] upper_add;
    wire [1:0] upper_xor2;
    wire [1:0] subtrahend;
    wire [1:0] minuend;
    wire [1:0] diff;
    wire       cin;
    wire [1:0] subtrahend_inv;
    wire [1:0] sum_temp;
    wire       carry_temp;

    assign lower_xor = in_cnt_reg[3:0] ^ in_cnt_reg[7:4];

    assign lower_add = in_cnt_reg[1:0] + in_cnt_reg[3:2];

    assign upper_xor2 = in_cnt_reg[5:4];

    // Conditional inversion subtractor for (lower_add - upper_xor2)
    // diff = lower_add - upper_xor2 = lower_add + (~upper_xor2) + 1
    assign minuend = lower_add;
    assign subtrahend = upper_xor2;
    assign cin = 1'b1;
    assign subtrahend_inv = ~subtrahend;
    assign {carry_temp, sum_temp} = {1'b0, minuend} + {1'b0, subtrahend_inv} + cin;
    assign diff = sum_temp[1:0];

    assign out_rand_wire = {lower_xor, diff};

endmodule