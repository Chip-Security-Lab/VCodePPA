//SystemVerilog
// Top level module
module parallel_range_detector_axi(
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

    // Internal signals
    wire [15:0] data_val;
    wire [15:0] range_start;
    wire [15:0] range_end;
    wire lower_than_range;
    wire inside_range;
    wire higher_than_range;

    // Instantiate register block
    register_block reg_block (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .data_val(data_val),
        .range_start(range_start),
        .range_end(range_end)
    );

    // Instantiate AXI write controller
    axi_write_ctrl write_ctrl (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .data_val(data_val),
        .range_start(range_start),
        .range_end(range_end)
    );

    // Instantiate AXI read controller
    axi_read_ctrl read_ctrl (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .data_val(data_val),
        .range_start(range_start),
        .range_end(range_end),
        .lower_than_range(lower_than_range),
        .inside_range(inside_range),
        .higher_than_range(higher_than_range)
    );

    // Instantiate range detector
    range_detector detector (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .data_val(data_val),
        .range_start(range_start),
        .range_end(range_end),
        .lower_than_range(lower_than_range),
        .inside_range(inside_range),
        .higher_than_range(higher_than_range)
    );

endmodule

// Register block module
module register_block(
    input wire clk,
    input wire rst_n,
    output reg [15:0] data_val,
    output reg [15:0] range_start,
    output reg [15:0] range_end
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_val <= 16'h0;
            range_start <= 16'h0;
            range_end <= 16'h0;
        end
    end

endmodule

// AXI Write Controller module
module axi_write_ctrl(
    input wire clk,
    input wire rst_n,
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    output reg [15:0] data_val,
    output reg [15:0] range_start,
    output reg [15:0] range_end
);

    localparam IDLE = 2'b00, ADDR = 2'b01, DATA = 2'b10, RESP = 2'b11;
    localparam ADDR_DATA_VAL = 4'h0;
    localparam ADDR_RANGE_START = 4'h4;
    localparam ADDR_RANGE_END = 4'h8;
    localparam RESP_OKAY = 2'b00;

    reg [1:0] write_state;
    reg [3:0] axi_awaddr_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            axi_awaddr_reg <= 4'h0;
        end else begin
            case (write_state)
                IDLE: begin
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        axi_awaddr_reg <= s_axi_awaddr[5:2];
                        write_state <= ADDR;
                    end
                end
                
                ADDR: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        
                        if (s_axi_wstrb[0]) begin
                            case (axi_awaddr_reg)
                                ADDR_DATA_VAL: data_val[7:0] <= s_axi_wdata[7:0];
                                ADDR_RANGE_START: range_start[7:0] <= s_axi_wdata[7:0];
                                ADDR_RANGE_END: range_end[7:0] <= s_axi_wdata[7:0];
                                default: ;
                            endcase
                        end
                        
                        if (s_axi_wstrb[1]) begin
                            case (axi_awaddr_reg)
                                ADDR_DATA_VAL: data_val[15:8] <= s_axi_wdata[15:8];
                                ADDR_RANGE_START: range_start[15:8] <= s_axi_wdata[15:8];
                                ADDR_RANGE_END: range_end[15:8] <= s_axi_wdata[15:8];
                                default: ;
                            endcase
                        end
                        
                        write_state <= DATA;
                    end
                end
                
                DATA: begin
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                    write_state <= RESP;
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end

endmodule

// AXI Read Controller module
module axi_read_ctrl(
    input wire clk,
    input wire rst_n,
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    input wire [15:0] data_val,
    input wire [15:0] range_start,
    input wire [15:0] range_end,
    input wire lower_than_range,
    input wire inside_range,
    input wire higher_than_range
);

    localparam IDLE = 2'b00, ADDR = 2'b01, DATA = 2'b10;
    localparam ADDR_DATA_VAL = 4'h0;
    localparam ADDR_RANGE_START = 4'h4;
    localparam ADDR_RANGE_END = 4'h8;
    localparam ADDR_STATUS = 4'hC;
    localparam RESP_OKAY = 2'b00;

    reg [1:0] read_state;
    reg [3:0] axi_araddr_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            axi_araddr_reg <= 4'h0;
            s_axi_rdata <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        axi_araddr_reg <= s_axi_araddr[5:2];
                        read_state <= ADDR;
                    end
                end
                
                ADDR: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid <= 1'b1;
                    
                    case (axi_araddr_reg)
                        ADDR_DATA_VAL: s_axi_rdata <= {16'h0000, data_val};
                        ADDR_RANGE_START: s_axi_rdata <= {16'h0000, range_start};
                        ADDR_RANGE_END: s_axi_rdata <= {16'h0000, range_end};
                        ADDR_STATUS: s_axi_rdata <= {29'h0, higher_than_range, inside_range, lower_than_range};
                        default: s_axi_rdata <= 32'h0;
                    endcase
                    
                    read_state <= DATA;
                end
                
                DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end

endmodule

// Range Detector module
module range_detector(
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_val,
    input wire [15:0] range_start,
    input wire [15:0] range_end,
    output reg lower_than_range,
    output reg inside_range,
    output reg higher_than_range
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_than_range <= 1'b0;
            inside_range <= 1'b0;
            higher_than_range <= 1'b0;
        end else begin
            lower_than_range <= (data_val < range_start);
            inside_range <= (data_val >= range_start) && (data_val <= range_end);
            higher_than_range <= (data_val > range_end);
        end
    end

endmodule