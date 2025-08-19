module tdp_ram_access_counter #(
    parameter DW = 24,
    parameter AW = 6
)(
    input clk, rst,
    // Port J
    input [AW-1:0] j_addr,
    input [DW-1:0] j_din,
    output reg [DW-1:0] j_dout,
    input j_we, j_oe,
    // Port K
    input [AW-1:0] k_addr,
    input [DW-1:0] k_din,
    output reg [DW-1:0] k_dout,
    input k_we, k_oe,
    // Debug interface
    output reg [31:0] j_write_count,
    output reg [31:0] j_read_count,
    output reg [31:0] k_write_count,
    output reg [31:0] k_read_count
);

(* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

// Port J access
always @(posedge clk) begin
    if (rst) begin
        j_write_count <= 0;
        j_read_count <= 0;
        j_dout <= 0;
    end else begin
        if (j_we) begin
            mem[j_addr] <= j_din;
            j_write_count <= j_write_count + 1;
        end
        
        if (j_oe) begin
            j_dout <= mem[j_addr];
            j_read_count <= j_read_count + 1;
        end else begin
            j_dout <= {DW{1'b0}};
        end
    end
end

// Port K access
always @(posedge clk) begin
    if (rst) begin
        k_write_count <= 0;
        k_read_count <= 0;
        k_dout <= 0;
    end else begin
        if (k_we) begin
            mem[k_addr] <= k_din;
            k_write_count <= k_write_count + 1;
        end
        
        if (k_oe) begin
            k_dout <= mem[k_addr];
            k_read_count <= k_read_count + 1;
        end else begin
            k_dout <= {DW{1'b0}};
        end
    end
end
endmodule