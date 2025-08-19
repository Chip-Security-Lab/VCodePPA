//SystemVerilog
module error_flagging_range_detector_axi_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [ADDR_WIDTH-1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [DATA_WIDTH-1:0] s_axil_wdata,
    input wire [(DATA_WIDTH/8)-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [ADDR_WIDTH-1:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal registers
    reg [31:0] data_in_reg;
    reg [31:0] lower_lim_reg;
    reg [31:0] upper_lim_reg;
    reg in_range_reg;
    reg error_flag_reg;
    
    // Address mapping
    localparam DATA_IN_ADDR    = 32'h00000000;
    localparam LOWER_LIM_ADDR  = 32'h00000004;
    localparam UPPER_LIM_ADDR  = 32'h00000008;
    localparam STATUS_ADDR     = 32'h0000000C;
    
    // Write state machine
    reg [1:0] write_state;
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    // Read state machine
    reg [1:0] read_state;
    
    // Write state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (write_state == IDLE) begin
                s_axil_awready <= 1'b1;
                s_axil_wready <= 1'b0;
                s_axil_bvalid <= 1'b0;
                if (s_axil_awvalid) begin
                    write_state <= DATA;
                    s_axil_awready <= 1'b0;
                end
            end else if (write_state == DATA) begin
                s_axil_wready <= 1'b1;
                if (s_axil_wvalid) begin
                    write_state <= RESP;
                    s_axil_wready <= 1'b0;
                    if (s_axil_awaddr == DATA_IN_ADDR) begin
                        data_in_reg <= s_axil_wdata;
                    end else if (s_axil_awaddr == LOWER_LIM_ADDR) begin
                        lower_lim_reg <= s_axil_wdata;
                    end else if (s_axil_awaddr == UPPER_LIM_ADDR) begin
                        upper_lim_reg <= s_axil_wdata;
                    end
                end
            end else if (write_state == RESP) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00;
                if (s_axil_bready) begin
                    write_state <= IDLE;
                    s_axil_bvalid <= 1'b0;
                end
            end
        end
    end
    
    // Read state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            if (read_state == IDLE) begin
                s_axil_arready <= 1'b1;
                s_axil_rvalid <= 1'b0;
                if (s_axil_arvalid) begin
                    read_state <= DATA;
                    s_axil_arready <= 1'b0;
                end
            end else if (read_state == DATA) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00;
                
                if (s_axil_araddr == DATA_IN_ADDR) begin
                    s_axil_rdata <= data_in_reg;
                end else if (s_axil_araddr == LOWER_LIM_ADDR) begin
                    s_axil_rdata <= lower_lim_reg;
                end else if (s_axil_araddr == UPPER_LIM_ADDR) begin
                    s_axil_rdata <= upper_lim_reg;
                end else if (s_axil_araddr == STATUS_ADDR) begin
                    s_axil_rdata <= {30'b0, error_flag_reg, in_range_reg};
                end else begin
                    s_axil_rdata <= 32'h0;
                end
                
                if (s_axil_rready) begin
                    read_state <= IDLE;
                    s_axil_rvalid <= 1'b0;
                end
            end
        end
    end
    
    // Core logic
    wire valid_range = (upper_lim_reg >= lower_lim_reg);
    wire in_bounds = (data_in_reg >= lower_lim_reg) && (data_in_reg <= upper_lim_reg);
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            in_range_reg <= 1'b0;
            error_flag_reg <= 1'b0;
        end else begin
            error_flag_reg <= !valid_range;
            in_range_reg <= valid_range && in_bounds;
        end
    end

endmodule