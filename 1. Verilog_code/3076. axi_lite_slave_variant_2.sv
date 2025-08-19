//SystemVerilog
module axi_lite_slave(
    input wire clk, rst_n,
    input wire [31:0] awaddr,
    input wire awreq,
    output reg awack,
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wreq,
    output reg wack,
    output reg [1:0] bresp,
    output reg breq,
    input wire back,
    input wire [31:0] araddr,
    input wire arreq,
    output reg arack,
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rreq,
    input wire rack
);

    localparam IDLE=2'b00, WRITE=2'b01, READ=2'b10, RESP=2'b11;
    reg [1:0] w_state, w_next;
    reg [1:0] r_state, r_next;
    reg [31:0] addr_reg;
    reg [31:0] mem [0:3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_state <= IDLE;
            r_state <= IDLE;
        end else begin
            w_state <= w_next;
            r_state <= r_next;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awack <= 1'b0;
            addr_reg <= 32'd0;
            wack <= 1'b0;
            breq <= 1'b0;
            bresp <= 2'b00;
            arack <= 1'b0;
            rdata <= 32'd0;
            rresp <= 2'b00;
            rreq <= 1'b0;
        end else begin
            // Write address channel control
            if (w_state == IDLE) begin
                awack <= 1'b1;
                if (awreq && awack) begin
                    addr_reg <= awaddr;
                    awack <= 1'b0;
                end
            end

            // Write data channel control
            if (w_state == WRITE) begin
                wack <= 1'b1;
                if (wreq && wack) begin
                    wack <= 1'b0;
                end
            end

            // Write response control
            if (w_state == WRITE && wreq && wack) begin
                bresp <= (addr_reg[3:2] < 2'd4) ? 2'b00 : 2'b10;
            end
            if (w_state == RESP) begin
                breq <= 1'b1;
                if (back && breq) begin
                    breq <= 1'b0;
                end
            end

            // Read address channel control
            if (r_state == IDLE) begin
                arack <= 1'b1;
                if (arreq && arack) begin
                    addr_reg <= araddr;
                    arack <= 1'b0;
                end
            end

            // Read data and response generation
            if (r_state == READ) begin
                if (addr_reg[3:2] < 2'd4) begin
                    rdata <= mem[addr_reg[3:2]];
                    rresp <= 2'b00;
                end else begin
                    rdata <= 32'd0;
                    rresp <= 2'b10;
                end
            end
            if (r_state == RESP) begin
                rreq <= 1'b1;
                if (rack && rreq) begin
                    rreq <= 1'b0;
                end
            end
        end
    end

    // Memory write operation
    always @(posedge clk) begin
        if (w_state == WRITE && wreq && wack && addr_reg[3:2] < 2'd4) begin
            if (wstrb[0]) mem[addr_reg[3:2]][7:0] <= wdata[7:0];
            if (wstrb[1]) mem[addr_reg[3:2]][15:8] <= wdata[15:8];
            if (wstrb[2]) mem[addr_reg[3:2]][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[addr_reg[3:2]][31:24] <= wdata[31:24];
        end
    end

    // Write next state logic
    always @(*) begin
        case (w_state)
            IDLE: w_next = (awreq && awack) ? WRITE : IDLE;
            WRITE: w_next = (wreq && wack) ? RESP : WRITE;
            RESP: w_next = (back && breq) ? IDLE : RESP;
            default: w_next = IDLE;
        endcase
    end

    // Read next state logic
    always @(*) begin
        case (r_state)
            IDLE: r_next = (arreq && arack) ? READ : IDLE;
            READ: r_next = RESP;
            RESP: r_next = (rack && rreq) ? IDLE : RESP;
            default: r_next = IDLE;
        endcase
    end

endmodule