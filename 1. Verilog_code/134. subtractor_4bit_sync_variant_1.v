module subtractor_4bit_axi_lite (
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
    reg [3:0] reg_a;
    reg [3:0] reg_b;
    reg [3:0] reg_diff;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    
    reg [1:0] state;
    
    // State machine control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: if (AWVALID) state <= WRITE;
                WRITE: if (WVALID) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
    
    // Write address channel control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b0;
        end else begin
            AWREADY <= (state == IDLE);
        end
    end
    
    // Write data channel control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            WREADY <= 1'b0;
        end else begin
            WREADY <= (state == WRITE);
        end
    end
    
    // Write response control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            BVALID <= (state == WRITE && WVALID);
            BRESP <= 2'b00;
        end
    end
    
    // Register write control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_a <= 4'b0;
            reg_b <= 4'b0;
        end else if (state == WRITE && WVALID) begin
            case (AWADDR[3:0])
                4'h0: reg_a <= WDATA[3:0];
                4'h4: reg_b <= WDATA[3:0];
            endcase
        end
    end
    
    // Read address channel control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY <= 1'b0;
        end else begin
            ARREADY <= ARVALID && !RVALID;
        end
    end
    
    // Read data channel control
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RVALID <= 1'b0;
            RDATA <= 32'b0;
            RRESP <= 2'b00;
        end else begin
            if (ARVALID && !RVALID) begin
                case (ARADDR[3:0])
                    4'h0: RDATA <= {28'b0, reg_a};
                    4'h4: RDATA <= {28'b0, reg_b};
                    4'h8: RDATA <= {28'b0, reg_diff};
                    default: RDATA <= 32'b0;
                endcase
                RVALID <= 1'b1;
                RRESP <= 2'b00;
            end else if (RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end
    
    // Core functionality - subtraction
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_diff <= 4'b0;
        end else begin
            reg_diff <= reg_a - reg_b;
        end
    end

endmodule