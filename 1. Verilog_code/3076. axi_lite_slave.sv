module axi_lite_slave(
    input wire clk, rst_n,
    // Write address channel
    input wire [31:0] awaddr,
    input wire awvalid,
    output reg awready,
    // Write data channel
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wvalid,
    output reg wready,
    // Write response channel
    output reg [1:0] bresp,
    output reg bvalid,
    input wire bready,
    // Read address channel
    input wire [31:0] araddr,
    input wire arvalid,
    output reg arready,
    // Read data channel
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    input wire rready
);
    localparam IDLE=2'b00, WRITE=2'b01, READ=2'b10, RESP=2'b11;
    reg [1:0] w_state, w_next;
    reg [1:0] r_state, r_next;
    reg [31:0] addr_reg;
    reg [31:0] mem [0:3]; // Small memory for demonstration
    
    // Write state machine
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            w_state <= IDLE;
            awready <= 1'b0;
            wready <= 1'b0;
            bvalid <= 1'b0;
            bresp <= 2'b00;
        end else begin
            w_state <= w_next;
            
            case (w_state)
                IDLE: begin
                    awready <= 1'b1;
                    if (awvalid && awready) begin
                        addr_reg <= awaddr;
                        awready <= 1'b0;
                    end
                end
                WRITE: begin
                    wready <= 1'b1;
                    if (wvalid && wready) begin
                        if (addr_reg[3:2] < 2'd4) begin
                            if (wstrb[0]) mem[addr_reg[3:2]][7:0] <= wdata[7:0];
                            if (wstrb[1]) mem[addr_reg[3:2]][15:8] <= wdata[15:8];
                            if (wstrb[2]) mem[addr_reg[3:2]][23:16] <= wdata[23:16];
                            if (wstrb[3]) mem[addr_reg[3:2]][31:24] <= wdata[31:24];
                            bresp <= 2'b00; // OKAY
                        end else
                            bresp <= 2'b10; // SLVERR
                        wready <= 1'b0;
                    end
                end
                RESP: begin
                    bvalid <= 1'b1;
                    if (bready && bvalid)
                        bvalid <= 1'b0;
                end
            endcase
        end
    
    // Read state machine
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            r_state <= IDLE;
            arready <= 1'b0;
            rvalid <= 1'b0;
            rresp <= 2'b00;
            rdata <= 32'd0;
        end else begin
            r_state <= r_next;
            
            case (r_state)
                IDLE: begin
                    arready <= 1'b1;
                    if (arvalid && arready) begin
                        addr_reg <= araddr;
                        arready <= 1'b0;
                    end
                end
                READ: begin
                    if (addr_reg[3:2] < 2'd4) begin
                        rdata <= mem[addr_reg[3:2]];
                        rresp <= 2'b00; // OKAY
                    end else begin
                        rdata <= 32'd0;
                        rresp <= 2'b10; // SLVERR
                    end
                end
                RESP: begin
                    rvalid <= 1'b1;
                    if (rready && rvalid)
                        rvalid <= 1'b0;
                end
            endcase
        end
    
    // Write next state logic
    always @(*)
        case (w_state)
            IDLE: w_next = (awvalid && awready) ? WRITE : IDLE;
            WRITE: w_next = (wvalid && wready) ? RESP : WRITE;
            RESP: w_next = (bready && bvalid) ? IDLE : RESP;
            default: w_next = IDLE;
        endcase
    
    // Read next state logic
    always @(*)
        case (r_state)
            IDLE: r_next = (arvalid && arready) ? READ : IDLE;
            READ: r_next = RESP;
            RESP: r_next = (rready && rvalid) ? IDLE : RESP;
            default: r_next = IDLE;
        endcase
endmodule