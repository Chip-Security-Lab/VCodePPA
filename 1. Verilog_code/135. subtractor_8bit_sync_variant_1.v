module subtractor_8bit_axi4lite (
    // AXI4-Lite Interface
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    // Internal registers
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg [7:0] reg_diff;
    
    // Write state machine
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // Read state machine
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
            reg_a <= 8'b0;
            reg_b <= 8'b0;
        end else begin
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
                        WREADY <= 1'b0;
                        case (AWADDR[3:0])
                            4'h0: reg_a <= WDATA[7:0];
                            4'h4: reg_b <= WDATA[7:0];
                        endcase
                        write_state <= WRITE_RESP;
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
    
    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b0;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
            RDATA <= 32'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    ARREADY <= 1'b1;
                    if (ARVALID) begin
                        ARREADY <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    RVALID <= 1'b1;
                    RRESP <= 2'b00;
                    case (ARADDR[3:0])
                        4'h0: RDATA <= {24'b0, reg_a};
                        4'h4: RDATA <= {24'b0, reg_b};
                        4'h8: RDATA <= {24'b0, reg_diff};
                        default: RDATA <= 32'b0;
                    endcase
                    if (RREADY) begin
                        RVALID <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
            endcase
        end
    end
    
    // Optimized subtraction logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_diff <= 8'b0;
        end else begin
            reg_diff <= reg_a - reg_b;
        end
    end
    
endmodule