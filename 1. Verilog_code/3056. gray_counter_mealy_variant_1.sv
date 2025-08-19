//SystemVerilog
module gray_counter_mealy_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    // AXI4-Lite Interface
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [ADDR_WIDTH-1:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [DATA_WIDTH-1:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [ADDR_WIDTH-1:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [DATA_WIDTH-1:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    // Internal registers
    reg [3:0] binary_count;
    reg [3:0] next_binary;
    reg [3:0] gray_out;
    reg enable;
    reg up_down;
    
    // Address mapping
    localparam CTRL_REG = 4'h0;
    localparam STATUS_REG = 4'h4;
    
    // Write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    // Read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    reg [1:0] write_state;
    reg [1:0] read_state;

    // Write FSM State Transition
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
        end else begin
            case (write_state)
                WRITE_IDLE: if (AWVALID) write_state <= WRITE_DATA;
                WRITE_DATA: if (WVALID) write_state <= WRITE_RESP;
                WRITE_RESP: if (BREADY) write_state <= WRITE_IDLE;
            endcase
        end
    end

    // Write FSM Control Signals
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    AWREADY <= 1'b1;
                    if (AWVALID) AWREADY <= 1'b0;
                end
                WRITE_DATA: begin
                    WREADY <= 1'b1;
                    if (WVALID) WREADY <= 1'b0;
                end
                WRITE_RESP: begin
                    BVALID <= 1'b1;
                    BRESP <= 2'b00;
                    if (BREADY) BVALID <= 1'b0;
                end
            endcase
        end
    end

    // Write Control Register
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            enable <= 1'b0;
            up_down <= 1'b0;
        end else if (write_state == WRITE_DATA && WVALID && AWADDR == CTRL_REG) begin
            enable <= WDATA[0];
            up_down <= WDATA[1];
        end
    end

    // Read FSM State Transition
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
        end else begin
            case (read_state)
                READ_IDLE: if (ARVALID) read_state <= READ_DATA;
                READ_DATA: if (RREADY) read_state <= READ_IDLE;
            endcase
        end
    end

    // Read FSM Control Signals
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    ARREADY <= 1'b1;
                    if (ARVALID) ARREADY <= 1'b0;
                end
                READ_DATA: begin
                    RVALID <= 1'b1;
                    RRESP <= 2'b00;
                    if (RREADY) RVALID <= 1'b0;
                end
            endcase
        end
    end

    // Read Data Generation
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RDATA <= 32'h0;
        end else if (read_state == READ_DATA) begin
            case (ARADDR)
                CTRL_REG: RDATA <= {30'h0, up_down, enable};
                STATUS_REG: RDATA <= {28'h0, gray_out};
                default: RDATA <= 32'h0;
            endcase
        end
    end

    // Binary Counter Logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            binary_count <= 4'b0000;
        end else if (enable) begin
            binary_count <= next_binary;
        end
    end

    // Next Binary and Gray Code Generation
    always @(*) begin
        next_binary = up_down ? (binary_count - 1'b1) : (binary_count + 1'b1);
        gray_out = {binary_count[3], binary_count[3:1] ^ binary_count[2:0]};
    end

endmodule