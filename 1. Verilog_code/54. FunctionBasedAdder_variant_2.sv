//SystemVerilog
module func_adder_axi_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input  wire                     s_axi_aclk,
    input  wire                     s_axi_aresetn,
    
    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [2:0]              s_axi_awprot,
    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    
    // Write Data Channel  
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    
    // Write Response Channel
    output wire [1:0]              s_axi_bresp,
    output wire                     s_axi_bvalid,
    input  wire                     s_axi_bready,
    
    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [2:0]              s_axi_arprot,
    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,
    
    // Read Data Channel
    output wire [DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]              s_axi_rresp,
    output wire                     s_axi_rvalid,
    input  wire                     s_axi_rready
);

    // Internal registers
    reg [4:0] alpha_reg;
    reg [4:0] beta_reg;
    reg [5:0] sum_reg;
    reg [5:0] sigma_reg;
    
    // AXI4-Lite interface signals
    reg [DATA_WIDTH-1:0] axi_rdata;
    reg axi_rvalid;
    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    reg [1:0] axi_bresp;
    reg [1:0] axi_rresp;
    
    // Address decoding
    localparam ALPHA_ADDR = 32'h00000000;
    localparam BETA_ADDR  = 32'h00000004;
    localparam SIGMA_ADDR = 32'h00000008;
    
    // Write address channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
        end else begin
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end
    
    // Write data channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && s_axi_awvalid && s_axi_wvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end
    
    // Write response channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0; // OKAY response
            end else begin
                if (s_axi_bready && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end
    
    // Read address channel
    reg axi_arready;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end
    
    // Read data channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b0;
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0; // OKAY response
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end
    
    // Register write logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            alpha_reg <= 5'b0;
            beta_reg  <= 5'b0;
        end else begin
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr)
                    ALPHA_ADDR: alpha_reg <= s_axi_wdata[4:0];
                    BETA_ADDR:  beta_reg  <= s_axi_wdata[4:0];
                    default: ;
                endcase
            end
        end
    end
    
    // Pipeline stage 2: Addition
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            sum_reg <= 6'b0;
        end else begin
            sum_reg <= alpha_reg + beta_reg;
        end
    end
    
    // Pipeline stage 3: Output registration
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            sigma_reg <= 6'b0;
        end else begin
            sigma_reg <= sum_reg;
        end
    end
    
    // Read data logic
    always @(*) begin
        case (s_axi_araddr)
            ALPHA_ADDR: axi_rdata = {{(DATA_WIDTH-5){1'b0}}, alpha_reg};
            BETA_ADDR:  axi_rdata = {{(DATA_WIDTH-5){1'b0}}, beta_reg};
            SIGMA_ADDR: axi_rdata = {{(DATA_WIDTH-6){1'b0}}, sigma_reg};
            default:    axi_rdata = {DATA_WIDTH{1'b0}};
        endcase
    end
    
    // Output assignments
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;

endmodule