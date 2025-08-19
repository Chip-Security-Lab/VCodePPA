//SystemVerilog
module rng_fib_lfsr_axi4lite #(
    parameter AXI_ADDR_WIDTH = 4,
    parameter AXI_DATA_WIDTH = 16
)(
    input                          s_axi_aclk,
    input                          s_axi_aresetn,

    // AXI4-Lite Write Address Channel
    input      [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input                           s_axi_awvalid,
    output reg                      s_axi_awready,

    // AXI4-Lite Write Data Channel
    input      [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input      [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                           s_axi_wvalid,
    output reg                      s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]                s_axi_bresp,
    output reg                      s_axi_bvalid,
    input                           s_axi_bready,

    // AXI4-Lite Read Address Channel
    input      [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input                           s_axi_arvalid,
    output reg                      s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]                s_axi_rresp,
    output reg                      s_axi_rvalid,
    input                           s_axi_rready
);

    // Internal signals/registers
    reg             clk;
    reg             rst;
    reg             en;
    reg [7:0]       lfsr_reg;
    wire            feedback_bit;
    reg [7:0]       multiplier_a;
    reg [7:0]       multiplier_b;
    reg [15:0]      product_reg;
    reg [3:0]       mul_counter;
    reg             mul_running;
    reg             mul_start;
    reg             mul_done;
    reg [15:0]      mul_result;
    reg [7:0]       rand_out;

    // AXI4-Lite internal state
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;

    // AXI4-Lite register map
    // 0x0: Control Register [en, rst]
    // 0x4: Random Output (rand_out)
    // 0x8: Multiplier Result (mul_result)
    // 0xC: Status [mul_done]

    // Internal registers for AXI
    reg axi_rst;
    reg axi_en;
    reg axi_rst_req;
    reg axi_en_req;

    // Write FSM
    reg [1:0] wr_state;
    localparam WR_IDLE  = 2'd0,
               WR_DATA  = 2'd1,
               WR_RESP  = 2'd2;

    // Read FSM
    reg [1:0] rd_state;
    localparam RD_IDLE  = 2'd0,
               RD_DATA  = 2'd1;

    // Write handshake
    wire wr_addr_handshake = s_axi_awvalid & s_axi_awready;
    wire wr_data_handshake = s_axi_wvalid & s_axi_wready;

    // Read handshake
    wire rd_addr_handshake = s_axi_arvalid & s_axi_arready;

    // AXI4-Lite write logic
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            wr_state      <= WR_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= RESP_OKAY;
            axi_rst_req   <= 1'b0;
            axi_en_req    <= 1'b0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    s_axi_bvalid  <= 1'b0;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        wr_state <= WR_RESP;
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        s_axi_bvalid  <= 1'b1;
                        s_axi_bresp   <= RESP_OKAY;
                        // Address decode and write
                        case (s_axi_awaddr[3:2])
                            2'b00: begin // Control Register
                                if (s_axi_wstrb[0]) begin
                                    axi_en_req  <= s_axi_wdata[0];
                                    axi_rst_req <= s_axi_wdata[1];
                                end
                            end
                            default: begin
                                s_axi_bresp <= RESP_SLVERR;
                            end
                        endcase
                    end
                end
                WR_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        wr_state     <= WR_IDLE;
                        axi_rst_req  <= 1'b0;
                        axi_en_req   <= 1'b0;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // AXI4-Lite read logic
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            rd_state      <= RD_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {AXI_DATA_WIDTH{1'b0}};
            s_axi_rresp   <= RESP_OKAY;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b0;
                        s_axi_rvalid  <= 1'b1;
                        s_axi_rresp   <= RESP_OKAY;
                        case (s_axi_araddr[3:2])
                            2'b00: s_axi_rdata <= {14'd0, axi_en, axi_rst};
                            2'b01: s_axi_rdata <= {8'd0, rand_out};
                            2'b10: s_axi_rdata <= mul_result;
                            2'b11: s_axi_rdata <= {15'd0, mul_done};
                            default: begin
                                s_axi_rdata <= {AXI_DATA_WIDTH{1'b0}};
                                s_axi_rresp <= RESP_SLVERR;
                            end
                        endcase
                        rd_state <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        rd_state     <= RD_IDLE;
                    end
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // Synchronize AXI signals to internal logic
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_rst <= 1'b1;
            axi_en  <= 1'b0;
        end else begin
            if (axi_rst_req)
                axi_rst <= 1'b1;
            else
                axi_rst <= 1'b0;
            if (axi_en_req)
                axi_en <= 1'b1;
            else if (axi_rst_req)
                axi_en <= 1'b0;
        end
    end

    // Internal logic clock and reset assignments
    always @(*) begin
        clk = s_axi_aclk;
        rst = axi_rst;
        en  = axi_en;
    end

    // LFSR Feedback
    assign feedback_bit = ^(lfsr_reg & 8'b10110100);

    // LFSR Process
    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg <= 8'hA5;
        end else if (en) begin
            lfsr_reg <= {lfsr_reg[6:0], feedback_bit};
        end
    end

    // Multiplier Start
    always @(posedge clk) begin
        if (rst) begin
            mul_start <= 1'b0;
        end else if (en) begin
            mul_start <= 1'b1;
        end else begin
            mul_start <= 1'b0;
        end
    end

    // Shift-Add Multiplier Control
    always @(posedge clk) begin
        if (rst) begin
            multiplier_a <= 8'd0;
            multiplier_b <= 8'd0;
            product_reg  <= 16'd0;
            mul_counter  <= 4'd0;
            mul_running  <= 1'b0;
            mul_done     <= 1'b0;
            mul_result   <= 16'd0;
        end else begin
            if (mul_start && !mul_running) begin
                multiplier_a <= lfsr_reg;
                multiplier_b <= 8'd42;
                product_reg  <= 16'd0;
                mul_counter  <= 4'd0;
                mul_running  <= 1'b1;
                mul_done     <= 1'b0;
            end else if (mul_running) begin
                if (mul_counter < 8) begin
                    if (multiplier_b[0]) begin
                        product_reg <= product_reg + (multiplier_a << mul_counter);
                    end
                    multiplier_b <= multiplier_b >> 1;
                    mul_counter  <= mul_counter + 1;
                end else begin
                    mul_running  <= 1'b0;
                    mul_done     <= 1'b1;
                    mul_result   <= product_reg[7:0];
                end
            end else begin
                mul_done <= 1'b0;
            end
        end
    end

    // Output assignment
    always @(*) begin
        rand_out = lfsr_reg;
    end

endmodule