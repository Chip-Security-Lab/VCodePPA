module subtractor_axi_lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel  
    input wire [DATA_WIDTH-1:0] s_axi_wdata,
    input wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

// Internal registers
reg [3:0] a_reg;
reg [3:0] b_reg;
reg [3:0] c_reg;
reg [3:0] d_reg;
reg [3:0] sum_ab_stage1;
reg [3:0] sum_ab_stage2;
reg [3:0] sum_abc_stage1;
reg [3:0] sum_abc_stage2;
reg [3:0] result_stage1;
reg [3:0] result_stage2;

// AXI-Lite state machine states
localparam IDLE = 2'b00;
localparam WRITE = 2'b01;
localparam READ = 2'b10;

reg [1:0] state;
reg [1:0] next_state;

// State machine
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// Next state logic
always @(*) begin
    case (state)
        IDLE: begin
            if (s_axi_awvalid && s_axi_wvalid)
                next_state = WRITE;
            else if (s_axi_arvalid)
                next_state = READ;
            else
                next_state = IDLE;
        end
        WRITE: begin
            if (s_axi_bready)
                next_state = IDLE;
            else
                next_state = WRITE;
        end
        READ: begin
            if (s_axi_rready)
                next_state = IDLE;
            else
                next_state = READ;
        end
        default: next_state = IDLE;
    endcase
end

// Write control signals
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_axi_awready <= 1'b0;
        s_axi_wready <= 1'b0;
        s_axi_bvalid <= 1'b0;
        s_axi_bresp <= 2'b00;
    end else begin
        case (state)
            IDLE: begin
                s_axi_awready <= 1'b0;
                s_axi_wready <= 1'b0;
                s_axi_bvalid <= 1'b0;
            end
            WRITE: begin
                s_axi_awready <= 1'b1;
                s_axi_wready <= 1'b1;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end
            default: begin
                s_axi_awready <= 1'b0;
                s_axi_wready <= 1'b0;
                s_axi_bvalid <= 1'b0;
            end
        endcase
    end
end

// Read control signals
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid <= 1'b0;
        s_axi_rresp <= 2'b00;
    end else begin
        case (state)
            IDLE: begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid <= 1'b0;
            end
            READ: begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
            end
            default: begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid <= 1'b0;
            end
        endcase
    end
end

// Write data handling
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        a_reg <= 4'b0;
        b_reg <= 4'b0;
        c_reg <= 4'b0;
        d_reg <= 4'b0;
    end else if (state == WRITE && s_axi_awvalid && s_axi_wvalid) begin
        case (s_axi_awaddr[3:0])
            4'h0: a_reg <= s_axi_wdata[3:0];
            4'h4: b_reg <= s_axi_wdata[3:0];
            4'h8: c_reg <= s_axi_wdata[3:0];
            4'hC: d_reg <= s_axi_wdata[3:0];
        endcase
    end
end

// Read data handling
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_axi_rdata <= 32'b0;
    end else if (state == READ && s_axi_arvalid) begin
        case (s_axi_araddr[3:0])
            4'h0: s_axi_rdata <= {28'b0, a_reg};
            4'h4: s_axi_rdata <= {28'b0, b_reg};
            4'h8: s_axi_rdata <= {28'b0, c_reg};
            4'hC: s_axi_rdata <= {28'b0, d_reg};
            4'h10: s_axi_rdata <= {28'b0, result_stage2};
            default: s_axi_rdata <= 32'b0;
        endcase
    end
end

// Pipeline logic - Stage 1
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        sum_ab_stage1 <= 4'b0;
    end else begin
        sum_ab_stage1 <= a_reg + b_reg;
    end
end

// Pipeline logic - Stage 2
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        sum_ab_stage2 <= 4'b0;
    end else begin
        sum_ab_stage2 <= sum_ab_stage1;
    end
end

// Pipeline logic - Stage 3
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        sum_abc_stage1 <= 4'b0;
    end else begin
        sum_abc_stage1 <= sum_ab_stage2 + c_reg;
    end
end

// Pipeline logic - Stage 4
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        sum_abc_stage2 <= 4'b0;
    end else begin
        sum_abc_stage2 <= sum_abc_stage1;
    end
end

// Pipeline logic - Stage 5
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        result_stage1 <= 4'b0;
    end else begin
        result_stage1 <= sum_abc_stage2 - d_reg;
    end
end

// Pipeline logic - Stage 6
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        result_stage2 <= 4'b0;
    end else begin
        result_stage2 <= result_stage1;
    end
end

endmodule