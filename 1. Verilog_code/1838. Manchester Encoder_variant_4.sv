//SystemVerilog
module manchester_encoder (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg         manchester_out
);

    localparam ADDR_CONTROL  = 4'h0;
    localparam ADDR_STATUS   = 4'h4;
    
    // Pipeline stage 1 registers
    reg  data_in_stage1;
    reg  polarity_stage1;
    reg  clk_div2_stage1;
    reg  [1:0] axi_write_state_stage1;
    reg  [1:0] axi_read_state_stage1;
    reg  [31:0] register_data_stage1;
    reg  write_valid_stage1;
    reg  read_valid_stage1;
    
    // Pipeline stage 2 registers  
    reg  data_in_stage2;
    reg  polarity_stage2;
    reg  clk_div2_stage2;
    reg  [1:0] axi_write_state_stage2;
    reg  [1:0] axi_read_state_stage2;
    reg  [31:0] register_data_stage2;
    reg  write_valid_stage2;
    reg  read_valid_stage2;
    
    // Pipeline stage 3 registers
    reg  data_in_stage3;
    reg  polarity_stage3;
    reg  clk_div2_stage3;
    reg  [1:0] axi_write_state_stage3;
    reg  [1:0] axi_read_state_stage3;
    reg  [31:0] register_data_stage3;
    reg  write_valid_stage3;
    reg  read_valid_stage3;

    localparam IDLE      = 2'b00;
    localparam ADDR      = 2'b01;
    localparam DATA      = 2'b10;
    localparam RESPONSE  = 2'b11;

    // Stage 1: Clock division and initial state
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            clk_div2_stage1 <= 1'b0;
            write_valid_stage1 <= 1'b0;
            read_valid_stage1 <= 1'b0;
        end else begin
            clk_div2_stage1 <= ~clk_div2_stage1;
            write_valid_stage1 <= s_axi_awvalid && s_axi_wvalid;
            read_valid_stage1 <= s_axi_arvalid;
        end
    end

    // Stage 2: Register operations
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            data_in_stage2 <= 1'b0;
            polarity_stage2 <= 1'b0;
            register_data_stage2 <= 32'h0;
            write_valid_stage2 <= 1'b0;
            read_valid_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            polarity_stage2 <= polarity_stage1;
            register_data_stage2 <= register_data_stage1;
            write_valid_stage2 <= write_valid_stage1;
            read_valid_stage2 <= read_valid_stage1;
            
            if (write_valid_stage1 && s_axi_awaddr[7:0] == ADDR_CONTROL && s_axi_wstrb[0]) begin
                data_in_stage2 <= s_axi_wdata[0];
                polarity_stage2 <= s_axi_wdata[1];
            end
            
            if (read_valid_stage1) begin
                case(s_axi_araddr[7:0])
                    ADDR_CONTROL: register_data_stage2 <= {30'h0, polarity_stage1, data_in_stage1};
                    ADDR_STATUS:  register_data_stage2 <= {31'h0, manchester_out};
                    default:      register_data_stage2 <= 32'h0;
                endcase
            end
        end
    end

    // Stage 3: Response generation
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
            write_valid_stage3 <= 1'b0;
            read_valid_stage3 <= 1'b0;
        end else begin
            data_in_stage3 <= data_in_stage2;
            polarity_stage3 <= polarity_stage2;
            clk_div2_stage3 <= clk_div2_stage2;
            write_valid_stage3 <= write_valid_stage2;
            read_valid_stage3 <= read_valid_stage2;
            
            if (write_valid_stage2) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end else if (s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
            
            if (read_valid_stage2) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata <= register_data_stage2;
                s_axi_rresp <= 2'b00;
            end else if (s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Manchester encoding output
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            manchester_out <= 1'b0;
        else
            manchester_out <= polarity_stage3 ? (data_in_stage3 ^ ~clk_div2_stage3) : (data_in_stage3 ^ clk_div2_stage3);
    end

    // AXI ready signals
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_arready <= 1'b0;
        end else begin
            s_axi_awready <= !write_valid_stage1;
            s_axi_wready <= !write_valid_stage1;
            s_axi_arready <= !read_valid_stage1;
        end
    end

endmodule