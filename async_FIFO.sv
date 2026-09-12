module async_fifo #(
  parameter DEPTH = 16,
  parameter DATA_WIDTH = 8
)
(
  //write logic
  input logic wr_clk,
  input logic wr_rst_n,
  input logic wr_en,
  input logic [DATA_WIDTH-1:0] wr_data,
  output logic wr_full,
  //read
  input logic rd_clk,
  input logic rd_rst_n,
  input logic rd_en,
  output logic [DATA_WIDTH-1:0] rd_data,
  output logic rd_empty
);
//memory instantiation
logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];
//pointer width parameter
localparam PTR_WIDTH = $clog2(DEPTH) + 1; // 1 + 4-> 5 bits

//write pointers
logic [PTR_WIDTH-1:0] wr_ptr_bin;
logic [PTR_WIDTH-1:0] wr_ptr_gray;
logic [PTR_WIDTH-1:0] wr_ptr_gray_ff1, wr_ptr_gray_ff2;

//read pointers 
logic [PTR_WIDTH-1:0] rd_ptr_bin;
logic [PTR_WIDTH-1:0] rd_ptr_gray;
logic [PTR_WIDTH-1:0] rd_ptr_gray_ff1, rd_ptr_gray_ff2;

//write combinational logic
logic [PTR_WIDTH-1:0] wr_ptr_bin_new;
logic [PTR_WIDTH-1:0] wr_ptr_gray_new;
assign wr_ptr_bin_new = (wr_ptr_bin + (wr_en && !wr_full));
assign wr_ptr_gray_new = ((wr_ptr_bin_new >> 1) ^ wr_ptr_bin_new);

//read combinational logic
logic [PTR_WIDTH-1:0] rd_ptr_bin_new;
logic [PTR_WIDTH-1:0] rd_ptr_gray_new;
assign rd_ptr_bin_new = (rd_ptr_bin + (rd_en && !rd_empty));
assign rd_ptr_gray_new = ((rd_ptr_bin_new >> 1) ^ rd_ptr_bin_new);

always_ff @ (posedge wr_clk or negedge wr_rst_n) begin
  if (!wr_rst_n) begin
    wr_full          <= 1'b0;
    wr_ptr_bin       <= '0;
    wr_ptr_gray      <= '0;
    wr_ptr_gray_ff1  <= '0;
    wr_ptr_gray_ff2  <= '0;
  end else begin 
    //2ff solution
    rd_ptr_gray_ff1 <= rd_ptr_gray;
    rd_ptr_gray_ff2 <= rd_ptr_gray_ff1;

    if (wr_en && !wr_full) begin
      //assign value at pointer address -> incr in bin/gray
      memory[wr_ptr_bin[$clog2(DEPTH)-1:0]] <= wr_data;
    end 
    wr_ptr_bin <= wr_ptr_bin_new;
    wr_ptr_gray <= wr_ptr_gray_new;
    wr_full <= ({~wr_ptr_gray_new[PTR_WIDTH-1],
                 ~wr_ptr_gray_new[PTR_WIDTH-2],
                 wr_ptr_gray_new[PTR_WIDTH-3:0]} == rd_ptr_gray_ff2);
  end
end

always_ff @ (posedge rd_clk or negedge rd_rst_n) begin
  if (!rd_rst_n) begin
    rd_empty         <= 1'b1;
    rd_data          <= '0;
    rd_ptr_bin       <= '0;
    rd_ptr_gray      <= '0;
    rd_ptr_gray_ff1  <= '0;
    rd_ptr_gray_ff2  <= '0;
  end else begin 
    //2ff solution
    wr_ptr_gray_ff1 <= wr_ptr_gray;
    wr_ptr_gray_ff2 <= wr_ptr_gray_ff1;

    if (rd_en && !rd_empty) begin
      rd_data <= memory[rd_ptr_bin[$clog2(DEPTH)-1:0]];
    end
    
    rd_ptr_bin <= rd_ptr_bin_new;
    rd_ptr_gray <= rd_ptr_gray_new;
    rd_empty <= (wr_ptr_gray_ff2 == rd_ptr_gray_new);
  end
end

endmodule
