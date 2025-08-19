module divider_4bit_with_remainder_axi (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel  
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

    // Register map
    localparam DIVIDEND_ADDR = 32'h0;
    localparam DIVISOR_ADDR = 32'h4;
    localparam QUOTIENT_ADDR = 32'h8;
    localparam REMAINDER_ADDR = 32'hC;

    // Internal registers
    reg [3:0] dividend;
    reg [3:0] divisor;
    reg [3:0] quotient;
    reg [3:0] remainder;
    
    // Division logic signals
    reg [3:0] x0, x1, x2;
    reg [7:0] temp;
    reg [3:0] b_inv;
    reg [3:0] b_inv_shift;
    reg [3:0] b_inv_final;

    // Write state machine
    reg [1:0] write_state;
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;

    // Read state machine
    reg [1:0] read_state;
    localparam R_IDLE = 2'b00;
    localparam R_ADDR = 2'b01;
    localparam R_DATA = 2'b10;

    // Write state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                    if (s_axi_awvalid) begin
                        write_state <= DATA;
                        s_axi_awready <= 1'b0;
                    end
                end
                
                DATA: begin
                    s_axi_wready <= 1'b1;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                        write_state <= RESP;
                        // Write data to registers
                        case (s_axi_awaddr[3:0])
                            DIVIDEND_ADDR[3:0]: dividend <= s_axi_wdata[3:0];
                            DIVISOR_ADDR[3:0]: divisor <= s_axi_wdata[3:0];
                        endcase
                    end
                end
                
                RESP: begin
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp <= 2'b00;
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Read state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= R_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;
        end else begin
            case (read_state)
                R_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                    if (s_axi_arvalid) begin
                        read_state <= R_DATA;
                        s_axi_arready <= 1'b0;
                    end
                end
                
                R_DATA: begin
                    s_axi_rvalid <= 1'b1;
                    case (s_axi_araddr[3:0])
                        DIVIDEND_ADDR[3:0]: s_axi_rdata <= {28'h0, dividend};
                        DIVISOR_ADDR[3:0]: s_axi_rdata <= {28'h0, divisor};
                        QUOTIENT_ADDR[3:0]: s_axi_rdata <= {28'h0, quotient};
                        REMAINDER_ADDR[3:0]: s_axi_rdata <= {28'h0, remainder};
                        default: s_axi_rdata <= 32'h0;
                    endcase
                    s_axi_rresp <= 2'b00;
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= R_IDLE;
                    end
                end
            endcase
        end
    end

    // Division logic
    always @(*) begin
        // Initial guess: x0 = 1/b ≈ 1/8
        x0 = 4'b0010; // 0.125 in fixed point
        
        // First iteration: x1 = x0*(2 - b*x0)
        temp = divisor * x0;
        x1 = x0 * (4'b1000 - temp[3:0]);
        
        // Second iteration: x2 = x1*(2 - b*x1)
        temp = divisor * x1;
        x2 = x1 * (4'b1000 - temp[3:0]);
        
        // Final reciprocal approximation
        b_inv = x2;
        
        // Calculate quotient using reciprocal
        temp = dividend * b_inv;
        quotient = temp[7:4];
        
        // Calculate remainder
        remainder = dividend - (quotient * divisor);
    end

endmodule