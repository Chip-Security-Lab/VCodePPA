//SystemVerilog
module karatsuba_mult_8bit_axi (
    // AXI4-Lite Interface
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    
    // Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    
    // Write Response Channel
    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    
    // Read Data Channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire s_axi_rready
);

    // Internal registers
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg [15:0] reg_result;
    reg [1:0] reg_state;
    
    // AXI4-Lite handshake signals
    reg aw_ready;
    reg w_ready;
    reg b_valid;
    reg ar_ready;
    reg r_valid;
    
    // Internal signals
    wire [3:0] a_high = reg_a[7:4];
    wire [3:0] a_low = reg_a[3:0];
    wire [3:0] b_high = reg_b[7:4];
    wire [3:0] b_low = reg_b[3:0];
    
    wire [7:0] z0;
    wire [7:0] z2;
    wire [7:0] z1;
    
    // Instantiate multipliers
    karatsuba_mult_4bit mult_low (
        .a(a_low),
        .b(b_low),
        .result(z0)
    );
    
    karatsuba_mult_4bit mult_high (
        .a(a_high),
        .b(b_high),
        .result(z2)
    );
    
    wire [4:0] sum_a = a_high + a_low;
    wire [4:0] sum_b = b_high + b_low;
    
    karatsuba_mult_4bit mult_mid (
        .a(sum_a[3:0]),
        .b(sum_b[3:0]),
        .result(z1)
    );
    
    // AXI4-Lite interface logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reg_a <= 8'b0;
            reg_b <= 8'b0;
            reg_result <= 16'b0;
            reg_state <= 2'b00;
            aw_ready <= 1'b0;
            w_ready <= 1'b0;
            b_valid <= 1'b0;
            ar_ready <= 1'b0;
            r_valid <= 1'b0;
        end else begin
            // Write address channel
            if (s_axi_awvalid && !aw_ready) begin
                aw_ready <= 1'b1;
            end else if (s_axi_awvalid && aw_ready) begin
                aw_ready <= 1'b0;
            end
            
            // Write data channel
            if (s_axi_wvalid && !w_ready) begin
                w_ready <= 1'b1;
                case (s_axi_awaddr[3:0])
                    4'h0: reg_a <= s_axi_wdata[7:0];
                    4'h4: reg_b <= s_axi_wdata[7:0];
                endcase
            end else if (s_axi_wvalid && w_ready) begin
                w_ready <= 1'b0;
                b_valid <= 1'b1;
            end
            
            // Write response channel
            if (s_axi_bready && b_valid) begin
                b_valid <= 1'b0;
            end
            
            // Read address channel
            if (s_axi_arvalid && !ar_ready) begin
                ar_ready <= 1'b1;
            end else if (s_axi_arvalid && ar_ready) begin
                ar_ready <= 1'b0;
                r_valid <= 1'b1;
            end
            
            // Read data channel
            if (s_axi_rready && r_valid) begin
                r_valid <= 1'b0;
            end
            
            // Update result
            reg_result <= (z2 << 8) + ((z1 - z0 - z2) << 4) + z0;
        end
    end
    
    // AXI4-Lite output assignments
    assign s_axi_awready = aw_ready;
    assign s_axi_wready = w_ready;
    assign s_axi_bresp = 2'b00;
    assign s_axi_bvalid = b_valid;
    assign s_axi_arready = ar_ready;
    assign s_axi_rdata = (s_axi_araddr[3:0] == 4'h8) ? {16'b0, reg_result} : 32'b0;
    assign s_axi_rresp = 2'b00;
    assign s_axi_rvalid = r_valid;
    
endmodule

module karatsuba_mult_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] result
);
    assign result = a * b;
endmodule