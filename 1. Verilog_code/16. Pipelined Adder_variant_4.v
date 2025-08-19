module pipelined_adder_axi_lite (
    // Clock and Reset
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

    // Internal registers
    reg [7:0] a_reg, b_reg;
    reg [7:0] sum_reg;
    reg valid_reg;
    
    // Stage 1 registers
    reg [3:0] a_low_s1, b_low_s1;
    reg [3:0] a_high_s1, b_high_s1;
    reg valid_s1;
    reg [4:0] sum_low_s1;
    
    // Stage 2 registers
    reg [3:0] a_high_s2, b_high_s2;
    reg [3:0] sum_low_s2;
    reg carry_s2;
    reg valid_s2;
    
    // AXI-Lite state machine
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Write address handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b1;
        end else begin
            s_axil_awready <= !s_axil_awvalid;
        end
    end
    
    // Write data handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b1;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                case (s_axil_awaddr[3:0])
                    4'h0: a_reg <= s_axil_wdata[7:0];
                    4'h4: b_reg <= s_axil_wdata[7:0];
                endcase
            end
            s_axil_wready <= !s_axil_wvalid;
        end
    end
    
    // Write response handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00;
            end else if (s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // Read address handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b1;
        end else begin
            s_axil_arready <= !s_axil_arvalid;
        end
    end
    
    // Read data handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'b0;
            s_axil_rresp <= 2'b00;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_axil_rvalid <= 1'b1;
                case (s_axil_araddr[3:0])
                    4'h0: s_axil_rdata <= {24'b0, a_reg};
                    4'h4: s_axil_rdata <= {24'b0, b_reg};
                    4'h8: s_axil_rdata <= {24'b0, sum_reg};
                    default: s_axil_rdata <= 32'b0;
                endcase
                s_axil_rresp <= 2'b00;
            end else if (s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // Pipeline stages
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            a_low_s1 <= 4'b0;
            b_low_s1 <= 4'b0;
            a_high_s1 <= 4'b0;
            b_high_s1 <= 4'b0;
            sum_low_s1 <= 5'b0;
            valid_s1 <= 1'b0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                a_low_s1 <= a_reg[3:0];
                b_low_s1 <= b_reg[3:0];
                a_high_s1 <= a_reg[7:4];
                b_high_s1 <= b_reg[7:4];
                sum_low_s1 <= a_reg[3:0] + b_reg[3:0];
                valid_s1 <= 1'b1;
            end else begin
                valid_s1 <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            a_high_s2 <= 4'b0;
            b_high_s2 <= 4'b0;
            sum_low_s2 <= 4'b0;
            carry_s2 <= 1'b0;
            valid_s2 <= 1'b0;
        end else begin
            if (valid_s1) begin
                a_high_s2 <= a_high_s1;
                b_high_s2 <= b_high_s1;
                sum_low_s2 <= sum_low_s1[3:0];
                carry_s2 <= sum_low_s1[4];
                valid_s2 <= 1'b1;
            end else begin
                valid_s2 <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sum_reg <= 8'b0;
            valid_reg <= 1'b0;
        end else begin
            if (valid_s2) begin
                sum_reg[3:0] <= sum_low_s2;
                sum_reg[7:4] <= a_high_s2 + b_high_s2 + carry_s2;
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

endmodule