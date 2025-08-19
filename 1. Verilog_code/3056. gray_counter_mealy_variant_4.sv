//SystemVerilog
module gray_counter_mealy_axi4lite(
    // AXI4-Lite Interface
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] awaddr,
    input wire awvalid,
    output reg awready,
    
    // Write Data Channel
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wvalid,
    output reg wready,
    
    // Write Response Channel
    output reg [1:0] bresp,
    output reg bvalid,
    input wire bready,
    
    // Read Address Channel
    input wire [31:0] araddr,
    input wire arvalid,
    output reg arready,
    
    // Read Data Channel
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    input wire rready
);

    // Internal signals
    reg [3:0] binary_count;
    reg [3:0] gray_out;
    reg enable;
    reg up_down;
    
    // Address mapping
    localparam CTRL_REG = 32'h0000;
    localparam COUNT_REG = 32'h0004;
    
    // Write FSM
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // Read FSM
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // Write FSM
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            awready <= 1'b0;
            wready <= 1'b0;
            bvalid <= 1'b0;
            enable <= 1'b0;
            up_down <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    awready <= 1'b1;
                    write_state <= WRITE_ADDR;
                end
                WRITE_ADDR: begin
                    if (awvalid) begin
                        awready <= 1'b0;
                        wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                WRITE_DATA: begin
                    if (wvalid) begin
                        wready <= 1'b0;
                        case (awaddr)
                            CTRL_REG: begin
                                enable <= wdata[0];
                                up_down <= wdata[1];
                            end
                        endcase
                        bvalid <= 1'b1;
                        bresp <= 2'b00;
                        write_state <= WRITE_RESP;
                    end
                end
                WRITE_RESP: begin
                    if (bready) begin
                        bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
            endcase
        end
    end
    
    // Read FSM
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            arready <= 1'b0;
            rvalid <= 1'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    arready <= 1'b1;
                    read_state <= READ_ADDR;
                end
                READ_ADDR: begin
                    if (arvalid) begin
                        arready <= 1'b0;
                        rvalid <= 1'b1;
                        case (araddr)
                            CTRL_REG: rdata <= {30'b0, up_down, enable};
                            COUNT_REG: rdata <= {28'b0, gray_out};
                            default: rdata <= 32'b0;
                        endcase
                        rresp <= 2'b00;
                        read_state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    if (rready) begin
                        rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
            endcase
        end
    end
    
    // Binary counter
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            binary_count <= 4'b0000;
        end else if (enable) begin
            if (up_down)
                binary_count <= binary_count - 1'b1;
            else
                binary_count <= binary_count + 1'b1;
        end
    end
    
    // Binary to Gray conversion
    always @(*) begin
        gray_out = {binary_count[3], binary_count[3:1] ^ binary_count[2:0]};
    end
    
endmodule