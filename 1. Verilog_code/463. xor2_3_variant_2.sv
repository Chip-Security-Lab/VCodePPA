//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: xor2_top.v
// Description: Top level module for 8-bit XOR operation with AXI4-Lite interface
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module xor2_top (
    // AXI4-Lite Interface
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal registers to store operands
    reg [7:0] reg_A;
    reg [7:0] reg_B;
    wire [7:0] xor_result;

    // Split the 8-bit operation into two 4-bit operations for better timing
    wire [3:0] lower_result;
    wire [3:0] upper_result;
    
    // Instantiate lower 4-bit XOR module
    xor2_4bit lower_xor (
        .A(reg_A[3:0]),
        .B(reg_B[3:0]),
        .Y(lower_result)
    );
    
    // Instantiate upper 4-bit XOR module
    xor2_4bit upper_xor (
        .A(reg_A[7:4]),
        .B(reg_B[7:4]),
        .Y(upper_result)
    );
    
    // Combine results
    assign xor_result = {upper_result, lower_result};

    // AXI4-Lite address decoding - Register map
    localparam ADDR_REG_A    = 4'h0;  // Address offset 0x00
    localparam ADDR_REG_B    = 4'h4;  // Address offset 0x04
    localparam ADDR_RESULT   = 4'h8;  // Address offset 0x08

    // AXI4-Lite FSM states
    localparam IDLE      = 2'b00;
    localparam WRITE     = 2'b01;
    localparam READ      = 2'b10;
    localparam RESPONSE  = 2'b11;

    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [3:0] addr_decode;

    // AXI4-Lite write transaction handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            reg_A <= 8'h00;
            reg_B <= 8'h00;
            addr_decode <= 4'h0;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axil_bresp <= 2'b00; // OKAY response
                    
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        // Both address and data are valid, can process in one cycle
                        s_axil_awready <= 1'b1;
                        s_axil_wready <= 1'b1;
                        addr_decode <= s_axil_awaddr[5:2];
                        write_state <= RESPONSE;
                        
                        // Write to appropriate register
                        if (s_axil_awaddr[5:2] == ADDR_REG_A) begin
                            reg_A <= s_axil_wdata[7:0];
                        end else if (s_axil_awaddr[5:2] == ADDR_REG_B) begin
                            reg_B <= s_axil_wdata[7:0];
                        end
                    end else if (s_axil_awvalid) begin
                        // Only address is valid
                        s_axil_awready <= 1'b1;
                        addr_decode <= s_axil_awaddr[5:2];
                        write_state <= WRITE;
                    end
                end
                
                WRITE: begin
                    s_axil_awready <= 1'b0; // Address has been accepted
                    
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b1;
                        write_state <= RESPONSE;
                        
                        // Write to appropriate register
                        if (addr_decode == ADDR_REG_A) begin
                            reg_A <= s_axil_wdata[7:0];
                        end else if (addr_decode == ADDR_REG_B) begin
                            reg_B <= s_axil_wdata[7:0];
                        end
                    end
                end
                
                RESPONSE: begin
                    s_axil_awready <= 1'b0;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b1;
                    
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end

    // AXI4-Lite read transaction handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        s_axil_rresp <= 2'b00; // OKAY response
                        read_state <= READ;
                        
                        // Prepare read data based on address
                        case (s_axil_araddr[5:2])
                            ADDR_REG_A: s_axil_rdata <= {24'h0, reg_A};
                            ADDR_REG_B: s_axil_rdata <= {24'h0, reg_B};
                            ADDR_RESULT: s_axil_rdata <= {24'h0, xor_result};
                            default: begin
                                s_axil_rdata <= 32'h0;
                                s_axil_rresp <= 2'b10; // SLVERR for invalid address
                            end
                        endcase
                    end
                end
                
                READ: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid <= 1'b1;
                    
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: xor2_4bit.v
// Description: 4-bit XOR operation module
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module xor2_4bit (
    input wire [3:0] A, B,
    output wire [3:0] Y
);
    // Implement using 1-bit XOR modules for better control over synthesis
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : xor_bit_gen
            xor2_1bit xor_bit_inst (
                .a(A[i]),
                .b(B[i]),
                .y(Y[i])
            );
        end
    endgenerate
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: xor2_1bit.v
// Description: Basic 1-bit XOR operation module
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module xor2_1bit (
    input wire a, b,
    output wire y
);
    // Primitive XOR operation
    assign y = a ^ b;
    
endmodule