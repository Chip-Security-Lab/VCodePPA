module mult_4bit_axi_lite (
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
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [7:0] prod_reg;
    
    // AXI4-Lite FSM states
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    
    reg [1:0] state;
    
    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
            AWREADY <= 1'b1;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            case (state)
                IDLE: begin
                    if (AWVALID && AWREADY) begin
                        AWREADY <= 1'b0;
                        WREADY <= 1'b1;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    if (WVALID && WREADY) begin
                        WREADY <= 1'b0;
                        BVALID <= 1'b1;
                        state <= IDLE;
                        
                        // Write data to registers based on address
                        case (AWADDR[3:0])
                            4'h0: a_reg <= WDATA[3:0];
                            4'h4: b_reg <= WDATA[3:0];
                        endcase
                    end
                end
            endcase
            
            if (BVALID && BREADY) begin
                BVALID <= 1'b0;
                AWREADY <= 1'b1;
            end
        end
    end
    
    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY <= 1'b1;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
        end else begin
            if (ARVALID && ARREADY) begin
                ARREADY <= 1'b0;
                RVALID <= 1'b1;
                
                // Read data from registers based on address
                case (ARADDR[3:0])
                    4'h0: RDATA <= {28'b0, a_reg};
                    4'h4: RDATA <= {28'b0, b_reg};
                    4'h8: RDATA <= {24'b0, prod_reg};
                    default: RDATA <= 32'b0;
                endcase
            end
            
            if (RVALID && RREADY) begin
                RVALID <= 1'b0;
                ARREADY <= 1'b1;
            end
        end
    end
    
    // Multiplier logic
    wire a_sign = a_reg[3];
    wire b_sign = b_reg[3];
    wire [3:0] a_abs = a_sign ? (~a_reg + 1'b1) : a_reg;
    wire [3:0] b_abs = b_sign ? (~b_reg + 1'b1) : b_reg;
    
    wire [7:0] pp0 = b_abs[0] ? {4'b0000, a_abs} : 8'b0;
    wire [7:0] pp1 = b_abs[1] ? {3'b000, a_abs, 1'b0} : 8'b0;
    wire [7:0] pp2 = b_abs[2] ? {2'b00, a_abs, 2'b00} : 8'b0;
    wire [7:0] pp3 = b_abs[3] ? {1'b0, a_abs, 3'b000} : 8'b0;
    
    wire [7:0] sum1 = pp0 + pp1;
    wire [7:0] sum2 = pp2 + pp3;
    wire [7:0] abs_prod = sum1 + sum2;
    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            prod_reg <= 8'b0;
        end else begin
            prod_reg <= (a_sign ^ b_sign) ? (~abs_prod + 1'b1) : abs_prod;
        end
    end

endmodule