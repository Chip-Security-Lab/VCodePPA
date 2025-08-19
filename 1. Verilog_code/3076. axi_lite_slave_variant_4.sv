//SystemVerilog
module axi_lite_slave(
    input wire clk, rst_n,
    // Write address channel
    input wire [31:0] awaddr,
    input wire awreq,
    output reg awack,
    // Write data channel
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wreq,
    output reg wack,
    // Write response channel
    output reg [1:0] bresp,
    output reg breq,
    input wire back,
    // Read address channel
    input wire [31:0] araddr,
    input wire arreq,
    output reg arack,
    // Read data channel
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rreq,
    input wire rack
);

    localparam IDLE=3'b000, ADDR=3'b001, DATA=3'b010, MEM=3'b011, RESP=3'b100;
    reg [2:0] w_state, w_next;
    reg [2:0] r_state, r_next;
    reg [31:0] addr_reg_stage1, addr_reg_stage2;
    reg [31:0] wdata_reg;
    reg [3:0] wstrb_reg;
    reg [31:0] mem [0:3];
    
    // Write state machine
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            w_state <= IDLE;
            awack <= 1'b0;
            wack <= 1'b0;
            breq <= 1'b0;
            bresp <= 2'b00;
            addr_reg_stage1 <= 32'd0;
            addr_reg_stage2 <= 32'd0;
            wdata_reg <= 32'd0;
            wstrb_reg <= 4'd0;
        end else begin
            w_state <= w_next;
            
            case (w_state)
                IDLE: begin
                    awack <= 1'b1;
                    if (awreq && awack) begin
                        addr_reg_stage1 <= awaddr;
                        awack <= 1'b0;
                    end
                end
                ADDR: begin
                    addr_reg_stage2 <= addr_reg_stage1;
                    wack <= 1'b1;
                    if (wreq && wack) begin
                        wdata_reg <= wdata;
                        wstrb_reg <= wstrb;
                        wack <= 1'b0;
                    end
                end
                DATA: begin
                    if (addr_reg_stage2[3:2] < 2'd4) begin
                        if (wstrb_reg[0]) mem[addr_reg_stage2[3:2]][7:0] <= wdata_reg[7:0];
                        if (wstrb_reg[1]) mem[addr_reg_stage2[3:2]][15:8] <= wdata_reg[15:8];
                        if (wstrb_reg[2]) mem[addr_reg_stage2[3:2]][23:16] <= wdata_reg[23:16];
                        if (wstrb_reg[3]) mem[addr_reg_stage2[3:2]][31:24] <= wdata_reg[31:24];
                        bresp <= 2'b00;
                    end else
                        bresp <= 2'b10;
                end
                RESP: begin
                    breq <= 1'b1;
                    if (back && breq)
                        breq <= 1'b0;
                end
            endcase
        end
    
    // Read state machine
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            r_state <= IDLE;
            arack <= 1'b0;
            rreq <= 1'b0;
            rresp <= 2'b00;
            rdata <= 32'd0;
            addr_reg_stage1 <= 32'd0;
            addr_reg_stage2 <= 32'd0;
        end else begin
            r_state <= r_next;
            
            case (r_state)
                IDLE: begin
                    arack <= 1'b1;
                    if (arreq && arack) begin
                        addr_reg_stage1 <= araddr;
                        arack <= 1'b0;
                    end
                end
                ADDR: begin
                    addr_reg_stage2 <= addr_reg_stage1;
                end
                DATA: begin
                    if (addr_reg_stage2[3:2] < 2'd4) begin
                        rdata <= mem[addr_reg_stage2[3:2]];
                        rresp <= 2'b00;
                    end else begin
                        rdata <= 32'd0;
                        rresp <= 2'b10;
                    end
                end
                RESP: begin
                    rreq <= 1'b1;
                    if (rack && rreq)
                        rreq <= 1'b0;
                end
            endcase
        end
    
    // Write next state logic
    always @(*)
        case (w_state)
            IDLE: w_next = (awreq && awack) ? ADDR : IDLE;
            ADDR: w_next = (wreq && wack) ? DATA : ADDR;
            DATA: w_next = MEM;
            MEM: w_next = RESP;
            RESP: w_next = (back && breq) ? IDLE : RESP;
            default: w_next = IDLE;
        endcase
    
    // Read next state logic
    always @(*)
        case (r_state)
            IDLE: r_next = (arreq && arack) ? ADDR : IDLE;
            ADDR: r_next = DATA;
            DATA: r_next = RESP;
            RESP: r_next = (rack && rreq) ? IDLE : RESP;
            default: r_next = IDLE;
        endcase
endmodule