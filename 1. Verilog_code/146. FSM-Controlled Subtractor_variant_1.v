module subtractor_pipeline_axi4lite (
    // AXI4-Lite Interface
    input wire ACLK,           // AXI4-Lite Clock
    input wire ARESETn,        // AXI4-Lite Reset (active low)
    
    // Write Address Channel
    input wire [31:0] AWADDR,  // Write address
    input wire AWVALID,        // Write address valid
    output reg AWREADY,        // Write address ready
    
    // Write Data Channel
    input wire [31:0] WDATA,   // Write data
    input wire [3:0] WSTRB,    // Write strobes
    input wire WVALID,         // Write valid
    output reg WREADY,         // Write ready
    
    // Write Response Channel
    output reg [1:0] BRESP,    // Write response
    output reg BVALID,         // Write response valid
    input wire BREADY,         // Write response ready
    
    // Read Address Channel
    input wire [31:0] ARADDR,  // Read address
    input wire ARVALID,        // Read address valid
    output reg ARREADY,        // Read address ready
    
    // Read Data Channel
    output reg [31:0] RDATA,   // Read data
    output reg [1:0] RRESP,    // Read response
    output reg RVALID,         // Read valid
    input wire RREADY          // Read ready
);

// Internal registers
reg [7:0] a_reg, b_reg;
reg [7:0] a_stage1, b_stage1;
reg [7:0] a_stage2, b_stage2;
reg [7:0] res_stage3;
reg [7:0] result_reg;

// Pipeline control signals
reg valid_stage1, valid_stage2, valid_stage3;

// Pipeline state definition
localparam IDLE = 2'b00;
localparam STAGE1 = 2'b01;
localparam STAGE2 = 2'b10;
localparam STAGE3 = 2'b11;

reg [1:0] state;

// AXI4-Lite state machine
localparam AXI_IDLE = 2'b00;
localparam AXI_WRITE = 2'b01;
localparam AXI_READ = 2'b10;

reg [1:0] axi_state;

// Write handling
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        AWREADY <= 1'b1;
        WREADY <= 1'b0;
        BVALID <= 1'b0;
        BRESP <= 2'b00;
        axi_state <= AXI_IDLE;
    end else begin
        case (axi_state)
            AXI_IDLE: begin
                if (AWVALID && AWREADY) begin
                    AWREADY <= 1'b0;
                    WREADY <= 1'b1;
                    axi_state <= AXI_WRITE;
                end
            end
            AXI_WRITE: begin
                if (WVALID && WREADY) begin
                    WREADY <= 1'b0;
                    case (AWADDR[3:0])
                        4'h0: a_reg <= WDATA[7:0];
                        4'h4: b_reg <= WDATA[7:0];
                    endcase
                    BVALID <= 1'b1;
                    BRESP <= 2'b00;
                    axi_state <= AXI_IDLE;
                end
            end
        endcase
        
        if (BVALID && BREADY) begin
            BVALID <= 1'b0;
            AWREADY <= 1'b1;
        end
    end
end

// Read handling
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        ARREADY <= 1'b1;
        RVALID <= 1'b0;
        RRESP <= 2'b00;
    end else begin
        if (ARVALID && ARREADY) begin
            ARREADY <= 1'b0;
            case (ARADDR[3:0])
                4'h0: RDATA <= {24'b0, a_reg};
                4'h4: RDATA <= {24'b0, b_reg};
                4'h8: RDATA <= {24'b0, result_reg};
                default: RDATA <= 32'b0;
            endcase
            RVALID <= 1'b1;
            RRESP <= 2'b00;
        end
        
        if (RVALID && RREADY) begin
            RVALID <= 1'b0;
            ARREADY <= 1'b1;
        end
    end
end

// Pipeline processing
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        a_stage1 <= 0;
        b_stage1 <= 0;
        valid_stage1 <= 0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                a_stage1 <= a_reg;
                b_stage1 <= b_reg;
                valid_stage1 <= 1;
                state <= STAGE1;
            end
            STAGE1: begin
                a_stage2 <= a_stage1;
                b_stage2 <= b_stage1;
                valid_stage2 <= valid_stage1;
                state <= STAGE2;
            end
            STAGE2: begin
                res_stage3 <= a_stage2 - b_stage2;
                valid_stage3 <= valid_stage2;
                state <= STAGE3;
            end
            STAGE3: begin
                result_reg <= res_stage3;
                state <= IDLE;
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule