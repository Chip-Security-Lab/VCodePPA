//SystemVerilog
module mult_unrolled_axi_lite (
    input wire ACLK,
    input wire ARESETn,
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    reg [3:0] x_reg;
    reg [3:0] y_reg;
    reg [7:0] result_reg;
    wire [7:0] result;
    
    wire [7:0] p0 = y_reg[0] ? {4'b0, x_reg} : 8'b0;
    wire [7:0] p1 = y_reg[1] ? {3'b0, x_reg, 1'b0} : 8'b0;
    wire [7:0] p2 = y_reg[2] ? {2'b0, x_reg, 2'b0} : 8'b0;
    wire [7:0] p3 = y_reg[3] ? {1'b0, x_reg, 3'b0} : 8'b0;
    assign result = p0 + p1 + p2 + p3;
    
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            x_reg <= 4'b0;
            y_reg <= 4'b0;
            result_reg <= 8'b0;
        end else begin
            result_reg <= result;
            case (write_state)
                WRITE_IDLE: begin
                    AWREADY <= 1'b1;
                    if (AWVALID) begin
                        write_state <= WRITE_DATA;
                        AWREADY <= 1'b0;
                    end
                end
                WRITE_DATA: begin
                    WREADY <= 1'b1;
                    if (WVALID) begin
                        case (AWADDR[3:0])
                            4'h0: x_reg <= WDATA[3:0];
                            4'h4: y_reg <= WDATA[3:0];
                        endcase
                        write_state <= WRITE_RESP;
                        WREADY <= 1'b0;
                    end
                end
                WRITE_RESP: begin
                    BVALID <= 1'b1;
                    BRESP <= 2'b00;
                    if (BREADY) begin
                        BVALID <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
            endcase
        end
    end
    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RDATA <= 32'b0;
            RRESP <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    ARREADY <= 1'b1;
                    if (ARVALID) begin
                        read_state <= READ_DATA;
                        ARREADY <= 1'b0;
                        case (ARADDR[3:0])
                            4'h0: RDATA <= {28'b0, x_reg};
                            4'h4: RDATA <= {28'b0, y_reg};
                            4'h8: RDATA <= {24'b0, result_reg};
                        endcase
                        RRESP <= 2'b00;
                        RVALID <= 1'b1;
                    end
                end
                READ_DATA: begin
                    if (RREADY) begin
                        RVALID <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
            endcase
        end
    end

endmodule