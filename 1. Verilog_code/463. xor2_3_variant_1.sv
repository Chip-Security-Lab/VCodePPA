//SystemVerilog
module xor2_3 (
    input wire aclk,                      // Clock signal
    input wire aresetn,                   // Active-low reset
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,      // Write address
    input wire [2:0] s_axil_awprot,       // Write protection type
    input wire s_axil_awvalid,            // Write address valid
    output wire s_axil_awready,           // Write address ready
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,       // Write data
    input wire [3:0] s_axil_wstrb,        // Write strobes
    input wire s_axil_wvalid,             // Write valid
    output wire s_axil_wready,            // Write ready
    
    // Write Response Channel
    output wire [1:0] s_axil_bresp,       // Write response
    output wire s_axil_bvalid,            // Write response valid
    input wire s_axil_bready,             // Response ready
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,      // Read address
    input wire [2:0] s_axil_arprot,       // Read protection type
    input wire s_axil_arvalid,            // Read address valid
    output wire s_axil_arready,           // Read address ready
    
    // Read Data Channel
    output wire [31:0] s_axil_rdata,      // Read data
    output wire [1:0] s_axil_rresp,       // Read response
    output wire s_axil_rvalid,            // Read valid
    input wire s_axil_rready              // Read ready
);

    // Register address map
    localparam REG_A_ADDR        = 4'h0;  // Address for operand A
    localparam REG_B_ADDR        = 4'h4;  // Address for operand B
    localparam REG_RESULT_ADDR   = 4'h8;  // Address for result
    localparam REG_CONTROL_ADDR  = 4'hC;  // Address for control/status

    // Internal registers
    reg [7:0] a_reg, b_reg;
    reg [7:0] result_reg;
    reg [1:0] control_reg;      // [0] = operation_done, [1] = last_flag
    
    // Internal signals
    wire [3:0] lower_result;
    wire [3:0] upper_result;
    
    // AXI4-Lite interface registers
    reg s_axil_awready_reg;
    reg s_axil_wready_reg;
    reg [1:0] s_axil_bresp_reg;
    reg s_axil_bvalid_reg;
    reg s_axil_arready_reg;
    reg [31:0] s_axil_rdata_reg;
    reg [1:0] s_axil_rresp_reg;
    reg s_axil_rvalid_reg;
    
    // Wire assignments for AXI4-Lite interface
    assign s_axil_awready = s_axil_awready_reg;
    assign s_axil_wready = s_axil_wready_reg;
    assign s_axil_bresp = s_axil_bresp_reg;
    assign s_axil_bvalid = s_axil_bvalid_reg;
    assign s_axil_arready = s_axil_arready_reg;
    assign s_axil_rdata = s_axil_rdata_reg;
    assign s_axil_rresp = s_axil_rresp_reg;
    assign s_axil_rvalid = s_axil_rvalid_reg;
    
    // Write address processing
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready_reg <= 1'b0;
        end else begin
            if (~s_axil_awready_reg && s_axil_awvalid) begin
                s_axil_awready_reg <= 1'b1;
            end else begin
                s_axil_awready_reg <= 1'b0;
            end
        end
    end
    
    // Write data processing
    reg [31:0] waddr;
    reg write_en;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready_reg <= 1'b0;
            write_en <= 1'b0;
            waddr <= 32'b0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                waddr <= s_axil_awaddr;
            end
            
            if (~s_axil_wready_reg && s_axil_wvalid && s_axil_awready) begin
                s_axil_wready_reg <= 1'b1;
                write_en <= 1'b1;
            end else begin
                s_axil_wready_reg <= 1'b0;
                write_en <= 1'b0;
            end
        end
    end
    
    // Write registers
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            control_reg <= 2'b0;
        end else begin
            if (write_en && s_axil_wvalid) begin
                case (waddr[3:0])
                    REG_A_ADDR: begin
                        if (s_axil_wstrb[0]) a_reg[7:0] <= s_axil_wdata[7:0];
                    end
                    REG_B_ADDR: begin
                        if (s_axil_wstrb[0]) begin
                            b_reg[7:0] <= s_axil_wdata[7:0];
                            // Automatically compute XOR result when B is written
                            control_reg[0] <= 1'b1; // Set operation_done flag
                        end
                    end
                    REG_CONTROL_ADDR: begin
                        if (s_axil_wstrb[0]) control_reg <= s_axil_wdata[1:0];
                    end
                endcase
            end
        end
    end
    
    // Write response
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid_reg <= 1'b0;
            s_axil_bresp_reg <= 2'b0;
        end else begin
            if (s_axil_wvalid && s_axil_wready && ~s_axil_bvalid_reg) begin
                s_axil_bvalid_reg <= 1'b1;
                s_axil_bresp_reg <= 2'b00; // OKAY response
            end else if (s_axil_bvalid_reg && s_axil_bready) begin
                s_axil_bvalid_reg <= 1'b0;
            end
        end
    end
    
    // Read address processing
    reg [31:0] raddr;
    reg read_en;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready_reg <= 1'b0;
            read_en <= 1'b0;
            raddr <= 32'b0;
        end else begin
            if (~s_axil_arready_reg && s_axil_arvalid) begin
                s_axil_arready_reg <= 1'b1;
                raddr <= s_axil_araddr;
                read_en <= 1'b1;
            end else begin
                s_axil_arready_reg <= 1'b0;
                read_en <= 1'b0;
            end
        end
    end
    
    // Read data processing
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid_reg <= 1'b0;
            s_axil_rdata_reg <= 32'b0;
            s_axil_rresp_reg <= 2'b0;
        end else begin
            if (read_en && ~s_axil_rvalid_reg) begin
                s_axil_rvalid_reg <= 1'b1;
                s_axil_rresp_reg <= 2'b00; // OKAY response
                
                case (raddr[3:0])
                    REG_A_ADDR: s_axil_rdata_reg <= {24'b0, a_reg};
                    REG_B_ADDR: s_axil_rdata_reg <= {24'b0, b_reg};
                    REG_RESULT_ADDR: s_axil_rdata_reg <= {24'b0, result_reg};
                    REG_CONTROL_ADDR: s_axil_rdata_reg <= {30'b0, control_reg};
                    default: s_axil_rdata_reg <= 32'b0;
                endcase
            end else if (s_axil_rvalid_reg && s_axil_rready) begin
                s_axil_rvalid_reg <= 1'b0;
            end
        end
    end
    
    // Store the result
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            result_reg <= 8'b0;
        end else if (control_reg[0]) begin
            // Update result when operation_done flag is set
            result_reg <= {upper_result, lower_result};
        end
    end
    
    // Instantiate lower 4-bit XOR submodule
    xor2_3_4bit lower_xor (
        .A_in(a_reg[3:0]),
        .B_in(b_reg[3:0]),
        .Y_out(lower_result)
    );
    
    // Instantiate upper 4-bit XOR submodule
    xor2_3_4bit upper_xor (
        .A_in(a_reg[7:4]),
        .B_in(b_reg[7:4]),
        .Y_out(upper_result)
    );
    
endmodule

// 4-bit XOR submodule (unchanged internal logic)
module xor2_3_4bit (
    input wire [3:0] A_in,
    input wire [3:0] B_in,
    output wire [3:0] Y_out
);
    // Use two 2-bit XOR modules
    wire [1:0] lower_bits;
    wire [1:0] upper_bits;
    
    xor2_3_2bit lower_bits_xor (
        .A_in(A_in[1:0]),
        .B_in(B_in[1:0]),
        .Y_out(lower_bits)
    );
    
    xor2_3_2bit upper_bits_xor (
        .A_in(A_in[3:2]),
        .B_in(B_in[3:2]),
        .Y_out(upper_bits)
    );
    
    assign Y_out = {upper_bits, lower_bits};
    
endmodule

// 2-bit XOR submodule (unchanged)
module xor2_3_2bit (
    input wire [1:0] A_in,
    input wire [1:0] B_in,
    output wire [1:0] Y_out
);
    // Instantiate two single-bit XOR modules
    xor2_3_1bit bit0_xor (
        .a(A_in[0]),
        .b(B_in[0]),
        .y(Y_out[0])
    );
    
    xor2_3_1bit bit1_xor (
        .a(A_in[1]),
        .b(B_in[1]),
        .y(Y_out[1])
    );
    
endmodule

// Single-bit XOR basic module (unchanged)
module xor2_3_1bit (
    input wire a,
    input wire b,
    output wire y
);
    // Basic single-bit XOR operation
    assign y = a ^ b;
    
endmodule