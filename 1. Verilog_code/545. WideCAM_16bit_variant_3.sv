//SystemVerilog
module cam_5_axi_lite (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
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
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // CAM Interface
    output reg match,
    output reg [15:0] stored_data
);

    // Internal registers
    reg [15:0] cam_data;
    reg write_en;
    
    // Write state machine
    localparam IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [1:0] next_write_state;
    
    // Read state machine
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [1:0] read_state;
    reg [1:0] next_read_state;
    
    // Write state machine - State transitions
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= IDLE;
        end else begin
            case (write_state)
                IDLE: begin
                    if (s_axil_awvalid) begin
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid) begin
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready) begin
                        write_state <= IDLE;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end
    
    // Write state machine - Control signals
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_en <= 1'b0;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    write_en <= 1'b0;
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b0;
                    end
                end
                
                WRITE_DATA: begin
                    s_axil_wready <= 1'b1;
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b0;
                        write_en <= 1'b1;
                        cam_data <= s_axil_wdata[15:0];
                    end
                end
                
                WRITE_RESP: begin
                    s_axil_bvalid <= 1'b1;
                    s_axil_bresp <= 2'b00;
                    write_en <= 1'b0;
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                    end
                end
                
                default: begin
                    s_axil_awready <= 1'b0;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    s_axil_bresp <= 2'b00;
                    write_en <= 1'b0;
                end
            endcase
        end
    end
    
    // Read state machine - State transitions
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axil_arvalid) begin
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    if (s_axil_rready) begin
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Read state machine - Control signals
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'b0;
            s_axil_rresp <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b0;
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rdata <= {16'b0, stored_data};
                    s_axil_rresp <= 2'b00;
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                    end
                end
                
                default: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid <= 1'b0;
                    s_axil_rdata <= 32'b0;
                    s_axil_rresp <= 2'b00;
                end
            endcase
        end
    end
    
    // CAM core logic - Data storage
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            stored_data <= 16'b0;
        end else if (write_en) begin
            stored_data <= cam_data;
        end
    end
    
    // CAM core logic - Match detection
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            match <= 1'b0;
        end else if (!write_en) begin
            match <= (stored_data == cam_data);
        end
    end

endmodule