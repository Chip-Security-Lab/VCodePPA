//SystemVerilog
module moore_4state_lock_axi4lite (
    // AXI4-Lite Interface
    input  wire         ACLK,
    input  wire         ARESETn,
    input  wire [31:0]  AWADDR,
    input  wire         AWVALID,
    output reg          AWREADY,
    input  wire [31:0]  WDATA,
    input  wire [3:0]   WSTRB,
    input  wire         WVALID,
    output reg          WREADY,
    output reg [1:0]    BRESP,
    output reg          BVALID,
    input  wire         BREADY,
    input  wire [31:0]  ARADDR,
    input  wire         ARVALID,
    output reg          ARREADY,
    output reg [31:0]   RDATA,
    output reg [1:0]    RRESP,
    output reg          RVALID,
    input  wire         RREADY
);

    // Internal signals
    reg [1:0] state, next_state;
    reg locked_reg;
    localparam WAIT = 2'b00,
               GOT1 = 2'b01,
               GOT10= 2'b10,
               UNLK = 2'b11;

    // AXI4-Lite Write FSM
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00,
               WRITE_ADDR = 2'b01,
               WRITE_DATA = 2'b10,
               WRITE_RESP = 2'b11;

    // AXI4-Lite Read FSM
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00,
               READ_ADDR = 2'b01,
               READ_DATA = 2'b10;

    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (AWVALID) begin
                        write_state <= WRITE_ADDR;
                        AWREADY <= 1'b1;
                    end
                end
                WRITE_ADDR: begin
                    AWREADY <= 1'b0;
                    if (WVALID) begin
                        write_state <= WRITE_DATA;
                        WREADY <= 1'b1;
                    end
                end
                WRITE_DATA: begin
                    WREADY <= 1'b0;
                    write_state <= WRITE_RESP;
                    BVALID <= 1'b1;
                end
                WRITE_RESP: begin
                    if (BREADY) begin
                        BVALID <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
            endcase
        end
    end

    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (ARVALID) begin
                        read_state <= READ_ADDR;
                        ARREADY <= 1'b1;
                    end
                end
                READ_ADDR: begin
                    ARREADY <= 1'b0;
                    read_state <= READ_DATA;
                    RVALID <= 1'b1;
                    RDATA <= {30'b0, locked_reg};
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

    // Moore FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= WAIT;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        locked_reg = (state == UNLK) ? 1'b0 : 1'b1;
        
        case (state)
            WAIT:  next_state = (WDATA[0] & WVALID & WREADY) ? GOT1 : WAIT;
            GOT1:  next_state = (WDATA[0] & WVALID & WREADY) ? GOT1 : GOT10;
            GOT10: next_state = (WDATA[0] & WVALID & WREADY) ? UNLK : WAIT;
            UNLK:  next_state = UNLK;
            default: next_state = WAIT;
        endcase
    end

    assign locked = locked_reg;

endmodule